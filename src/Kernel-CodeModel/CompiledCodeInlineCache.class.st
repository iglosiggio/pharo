"
This class is responsible for storing all the inline caches of a given method. It has a `CompiledMethod` layout. The slots are used for storing language-visible information and the bytes are used for internal pointers (this means: don't modify them!).

The first slot for this class is a CompiledCode-compatible header. After that a series of inline caches follow. Each cache is a list of options followed by the fallback. Each option is two slots (one for the class and one for the method). The fallback is one slot (the information necessary for invoking it).

On the private data side we have a series of pointers. The accessors implemented will show those pointers as `ExternalAddress` instances. The same rough structure follows: one pointer to machine code for each option (pointing to a primitive / an interpreter / a piece of jit-ed machine code) and a pointer to the fallback handler after that.
"
Class {
	#name : 'CompiledCodeInlineCache',
	#superclass : 'Object',
	#type : 'compiledMethod',
	#category : 'Kernel-CodeModel-Methods',
	#package : 'Kernel-CodeModel',
	#tag : 'Methods'
}

{ #category : 'instance creation' }
CompiledCodeInlineCache class >> basicNew: numberOfBytes header: headerWord [
	"Primitive. Answer an instance of me. The number of literals (and other
	 information) is specified by the headerWord (see my class comment).
	 The first argument specifies the number of fields for bytecodes in the
	 method. Fail if either argument is not a SmallInteger, or if numberOfBytes
	 is negative, or if memory is low. Once the header of a method is set by
	 this primitive, it cannot be changed to change the number of literals.
	 Essential. See Object documentation whatIsAPrimitive."

	<primitive: 79 error: ec>
	^self primitiveFailed
]

{ #category : 'instance creation' }
CompiledCodeInlineCache class >> for: aCompiledCode [
	| messages wordSize cache bytesSize slotsSize |
	messages := aCompiledCode localMessages.
	wordSize := Smalltalk wordSize.
	
	self assert: wordSize = 8 description: '32 bit VMs are not yet supported'.

	bytesSize := (self inlinedAttempts + 1) * messages size * Smalltalk wordSize.
	slotsSize := 1 + 1 + (self sendSiteCacheSize * messages size).
	cache := self basicNew: bytesSize header: slotsSize.
	cache compiledCode: aCompiledCode.
	messages withIndexDo: [ :selector :i |
		cache fallbackDataAtSendSite: i put: selector ].
	^ cache
]

{ #category : 'instance creation' }
CompiledCodeInlineCache class >> forSendsites: aSendsiteList [
	| wordSize cache bytesSize slotsSize |
	wordSize := Smalltalk wordSize.
	
	self assert: wordSize = 8 description: '32 bit VMs are not yet supported'.

	bytesSize := (self inlinedAttempts + 1) * aSendsiteList size * Smalltalk wordSize.
	slotsSize := 1 + 1 + (self sendSiteCacheSize * aSendsiteList size).
	cache := self basicNew: bytesSize header: slotsSize.
	cache compiledCode: nil.
	aSendsiteList withIndexDo: [ :sendSiteAssoc :i |
		cache fallbackDataAtSendSite: i put: sendSiteAssoc key ].
	^ cache
]

{ #category : 'accessing' }
CompiledCodeInlineCache class >> inlinedAttempts [
	^ 3
]

{ #category : 'accessing' }
CompiledCodeInlineCache class >> nativePointersPerSendSite [
	^ self inlinedAttempts + 1 "fallback"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> pointerIdxForFallbackAt: aSendSiteIdx [
	^ 1 + "initial slot"
		(self nativePointersPerSendSite * (aSendSiteIdx - 1)) + "skip previous ICs"
		self inlinedAttempts "skip previous pointers on this IC"
]

{ #category : 'accessing' }
CompiledCodeInlineCache class >> pointerIdxForNativeAt: aSendSiteIdx forOption: anOptionIdx [
	^ 1 + "initial slot"
		(self nativePointersPerSendSite * (aSendSiteIdx - 1)) + "skip previous send sites"
		(anOptionIdx - 1) "skip previous options"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> sendSiteCacheSize [
	^ self inlinedAttempts * ( " for each attempt..."
			1 + "cached class"
			1 "cached method"
		) +
		1 "cached fallback"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotAtSendSite: aSendSiteIndex [ 
	^ 1 + "initial slot"
		1 + "skip header"
		1 + "skip compiled code"
		((aSendSiteIndex - 1) * self sendSiteCacheSize) "skip each previous send site"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForClassAtSendSite: aSendSiteIndex forOption: anOptionIdx [
	^ (self slotAtSendSite: aSendSiteIndex) + ((
			1 + "class to check"
			1 "method to call"
		) * (anOptionIdx - 1)) "the previous options"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForCompiledCode [
	^ 2 "ignored header"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForFallbackDataAtSendSite: aSendSiteIndex [
	^ (self slotAtSendSite: aSendSiteIndex + 1) - 1 "One slot before the next SendSite"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForMethodAtSendSite: aSendSiteIndex forOption: anOptionIdx [
	^ (self slotForClassAtSendSite: aSendSiteIndex forOption: anOptionIdx) +
		1 "the method for this option"
]

{ #category : 'private' }
CompiledCodeInlineCache >> assertValidSendsite: aSendSiteIdx [ 
	self assert: (aSendSiteIdx between: 1 and: self cacheSize) description: 'Invalid send site index'.
]

{ #category : 'private' }
CompiledCodeInlineCache >> assertValidSendsite: aSendSiteIdx andOption: anOptionIdx [
	self assertValidSendsite: aSendSiteIdx.
	self assert: (anOptionIdx between: 1 and: self class inlinedAttempts) description: 'Invalid option index'
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> cacheSize [
	^ self slotSize // self class sendSiteCacheSize
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> classAtSendsite: aSendSiteIdx forOption: anOptionIdx [ 
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForClassAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	^ self objectAt: slot
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> classAtSendsite: aSendSiteIdx forOption: anOptionIdx put: aClass [
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForClassAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	self objectAt: slot put: aClass
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> compiledCode [
	^ self objectAt: self class slotForCompiledCode.
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> compiledCode: aCompiledCode [
	self objectAt: self class slotForCompiledCode put: aCompiledCode
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackDataAtSendSite: aSendSiteIdx [
	| slot |
	slot := self class slotForFallbackDataAtSendSite: aSendSiteIdx.
	^ self objectAt: slot
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackDataAtSendSite: aSendSiteIdx put: aFallbackDataObject [
	| slot |
	slot := self class slotForFallbackDataAtSendSite: aSendSiteIdx.
	self objectAt: slot put: aFallbackDataObject
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackNativeAtSendSite: aSendSiteIdx [
	| pointerIdx |
	self assertValidSendsite: aSendSiteIdx.
	pointerIdx := self class pointerIdxForFallbackAt: aSendSiteIdx.
	^ self pointerAt: pointerIdx
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackNativeAtSendSite: aSendSiteIdx put: anExternalAddress [
	| pointerIdx |
	self assertValidSendsite: aSendSiteIdx.
	pointerIdx := self class pointerIdxForFallbackAt: aSendSiteIdx.
	self pointerAt: pointerIdx put: anExternalAddress
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> header [
	^ self objectAt: 1.
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> inspectorNodes [
	"Answer a list of attributes as nodes"
	| nodes |

	nodes := OrderedCollection new.

	nodes add:
		(StInspectorDynamicNode
			hostObject: self
			label: 'header'
			value: self header).

	nodes add:
		(StInspectorDynamicNode
			hostObject: self
			label: 'compiledCode'
			value: self compiledCode).

	1 to: self cacheSize do: [ :sendSiteIdx |
		| fallbackData fallbackNative |

		1 to: self class inlinedAttempts do: [ :optionIdx |
			| class method native |

			class := self classAtSendsite: sendSiteIdx forOption: optionIdx.
			nodes add:
				(StInspectorDynamicNode
					hostObject: self
					label: 'PIC ', sendSiteIdx asString, ' - Option ', optionIdx asString, ' - Class'
					value: class).

			method := self methodAtSendSite: sendSiteIdx forOption: optionIdx.
			nodes add:
				(StInspectorDynamicNode
					hostObject: self
					label: 'PIC ', sendSiteIdx asString, ' - Option ', optionIdx asString, ' - Method'
					value: method).

			native := self nativeAtSendSite: sendSiteIdx forOption: optionIdx.
			nodes add:
				(StInspectorDynamicNode
					hostObject: self
					label: 'PIC ', sendSiteIdx asString, ' - Option ', optionIdx asString, ' - Native'
					value: native) ].

		fallbackData := self fallbackDataAtSendSite: sendSiteIdx.
		nodes add:
			(StInspectorDynamicNode
				hostObject: self
				label: 'PIC ', sendSiteIdx asString, ' - Fallback Data'
				value: fallbackData).

		fallbackNative := self fallbackNativeAtSendSite: sendSiteIdx.
		nodes add:
			(StInspectorDynamicNode
				hostObject: self
				label: 'PIC ', sendSiteIdx asString, ' - Fallback Native'
				value: fallbackNative) ].

	^ nodes
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> methodAtSendSite: aSendSiteIdx forOption: anOptionIdx [ 
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForMethodAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	^ self objectAt: slot
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> methodAtSendSite: aSendSiteIdx forOption: anOptionIdx put: aCompiledCode [
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForMethodAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	self objectAt: slot put: aCompiledCode
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> nativeAtSendSite: aSendSiteIdx forOption: anOptionIdx [ 
	| pointerIdx |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	pointerIdx := self class pointerIdxForNativeAt: aSendSiteIdx forOption: anOptionIdx.
	^ self pointerAt: pointerIdx
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> nativeAtSendSite: aSendSiteIdx forOption: anOptionIdx put: anExternalAddress [
	| pointerIdx |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	pointerIdx := self class pointerIdxForNativeAt: aSendSiteIdx forOption: anOptionIdx.
	self pointerAt: pointerIdx put: anExternalAddress
]

{ #category : 'private' }
CompiledCodeInlineCache >> nativeSectionStart [
	| wordSize |
	wordSize := Smalltalk wordSize.
	^ wordSize "header" + (self slotSize * wordSize) "vm data" + 1.
]

{ #category : 'private' }
CompiledCodeInlineCache >> objectAt: index [
	"Primitive. Answer the method header (if index=1) or a literal (if index
	>1) from the receiver. Essential. See Object documentation
	whatIsAPrimitive."

	<primitive: 68 error: ec>
	self primitiveFailed
]

{ #category : 'private' }
CompiledCodeInlineCache >> objectAt: index put: value [
	"Primitive. Store the value argument into a literal in the receiver. An
	index of 2 corresponds to the first literal. Fails if the index is less than 2
	or greater than the number of literals. Answer the value as the result.
	Normally only the compiler sends this message, because only the
	compiler stores values in CompiledMethods. Essential. See Object
	documentation whatIsAPrimitive."

	<primitive: 69 error: ec>
	self primitiveFailed
]

{ #category : 'private' }
CompiledCodeInlineCache >> pointerAt: aPointerIdx [
	| wordSize byteStart result |
	wordSize := Smalltalk wordSize.
	byteStart := self nativeSectionStart + ((aPointerIdx - 1) * wordSize).
	result := ExternalAddress new.
	1 to: wordSize do: [ :i |
		result at: i put: (self at: byteStart - 1 + i) ].
	^ result 
]

{ #category : 'private' }
CompiledCodeInlineCache >> pointerAt: aPointerIdx put: anExternalAddress [ 
	| wordSize byteStart |
	wordSize := Smalltalk wordSize.
	byteStart := self nativeSectionStart + ((aPointerIdx - 1) * wordSize).
	1 to: wordSize do: [ :i |
		self at: byteStart - 1 + i put: (anExternalAddress at: i) ]
]

{ #category : 'private' }
CompiledCodeInlineCache >> slotSize [
	^ self header bitAnd: 16rFFFF.
]

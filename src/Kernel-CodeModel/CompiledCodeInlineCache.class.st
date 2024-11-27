"
This class is responsible for storing all the inline caches of a given method. It has a `CompiledMethod` layout. The slots are used for storing language-visible information and the bytes are used for internal pointers (this means: don't modify them!).

The first slot for this class is a CompiledCode-compatible header. After that a series of inline caches follow. Each cache is a list of options followed by the fallback. Each option is two slots (one for the class and one for the method). The fallback is one slot (the information necessary for invoking it).

On the private data side we have a series of pointers. The accessors implemented will show those pointers as `ExternalAddress` instances. The same rough structure follows: one pointer to machine code for each option (pointing to a primitive / an interpreter / a piece of jit-ed machine code) and a pointer to the fallback handler after that.
"
Class {
	#name : 'CompiledCodeInlineCache',
	#superclass : 'Array',
	#type : 'variable',
	#category : 'Kernel-CodeModel-Methods',
	#package : 'Kernel-CodeModel',
	#tag : 'Methods'
}

{ #category : 'instance creation' }
CompiledCodeInlineCache class >> for: aCompiledCode [
	^ (self forSendsites: aCompiledCode localMessages)
		compiledCode: aCompiledCode;
		yourself.
]

{ #category : 'instance creation' }
CompiledCodeInlineCache class >> forSendsites: aSendsiteList [
	| cache slotsSize |

	slotsSize := 1 + (self sendSiteCacheSize * aSendsiteList size).
	cache := self new: slotsSize.
	aSendsiteList withIndexDo: [ :sendSiteAssoc :i |
		cache fallbackDataAtSendSite: i put: sendSiteAssoc ].
	^ cache
]

{ #category : 'accessing' }
CompiledCodeInlineCache class >> inlinedAttempts [
	^ 3
]

{ #category : 'private' }
CompiledCodeInlineCache class >> sendSiteCacheSize [
	^ self inlinedAttempts * ( " for each attempt..."
			1 + "cached class"
			1 "cached method"
		) +
		1 + "cached fallback data"
		1 "cached fallback method"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotAtSendSite: aSendSiteIndex [ 
	^ 1 + "initial slot"
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
	^ 1
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForFallbackDataAtSendSite: aSendSiteIndex [
	^ (self slotAtSendSite: aSendSiteIndex + 1) - 2 "Two slots before the next SendSite"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForFallbackMethodAtSendSite: aSendSiteIndex [
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
	^ self size // self class sendSiteCacheSize
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> classAtSendsite: aSendSiteIdx forOption: anOptionIdx [ 
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForClassAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	^ self at: slot
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> classAtSendsite: aSendSiteIdx forOption: anOptionIdx put: aClass [
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForClassAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	^ self at: slot put: aClass
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> compiledCode [
	^ self at: self class slotForCompiledCode.
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> compiledCode: aCompiledCode [
	^ self at: self class slotForCompiledCode put: aCompiledCode
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackDataAtSendSite: aSendSiteIdx [
	| slot |
	slot := self class slotForFallbackDataAtSendSite: aSendSiteIdx.
	^ self at: slot
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackDataAtSendSite: aSendSiteIdx put: aFallbackDataObject [
	| slot |
	slot := self class slotForFallbackDataAtSendSite: aSendSiteIdx.
	^ self at: slot put: aFallbackDataObject
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackMethodAtSendSite: aSendSiteIdx [
	| slot |
	slot := self class slotForFallbackMethodAtSendSite: aSendSiteIdx.
	^ self at: slot
]

{ #category : 'fallback' }
CompiledCodeInlineCache >> fallbackMethodAtSendSite: aSendSiteIdx put: aFallbackDataObject [
	| slot |
	slot := self class slotForFallbackMethodAtSendSite: aSendSiteIdx.
	^ self at: slot put: aFallbackDataObject
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> inspectorNodes [
	"Answer a list of attributes as nodes"
	| nodes |

	nodes := OrderedCollection new.

	nodes add:
		(StInspectorDynamicNode
			hostObject: self
			label: 'compiledCode'
			value: self compiledCode).

	1 to: self cacheSize do: [ :sendSiteIdx |
		| fallbackData fallbackMethod |

		1 to: self class inlinedAttempts do: [ :optionIdx |
			| class method |

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
					value: method) ].

		fallbackData := self fallbackDataAtSendSite: sendSiteIdx.
		nodes add:
			(StInspectorDynamicNode
				hostObject: self
				label: 'PIC ', sendSiteIdx asString, ' - Fallback Data'
				value: fallbackData).

		fallbackMethod := self fallbackMethodAtSendSite: sendSiteIdx.
		nodes add:
			(StInspectorDynamicNode
				hostObject: self
				label: 'PIC ', sendSiteIdx asString, ' - Fallback Method'
				value: fallbackMethod) ].

	^ nodes
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> methodAtSendSite: aSendSiteIdx forOption: anOptionIdx [ 
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForMethodAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	^ self at: slot
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> methodAtSendSite: aSendSiteIdx forOption: anOptionIdx put: aCompiledCode [
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotForMethodAtSendSite: aSendSiteIdx forOption: anOptionIdx.
	^ self at: slot put: aCompiledCode
]

{ #category : 'private' }
CompiledCodeInlineCache >> nextFreeOptionAtSendSite: sendSiteIndex [ 
	1 to: self class inlinedAttempts do: [ :optionIndex |
		(self classAtSendsite: sendSiteIndex forOption: optionIndex)
			ifNil: [ ^ optionIndex ] ].
	^ nil
]

{ #category : 'nil' }
CompiledCodeInlineCache >> runFallbackFor: sendSiteIndex withArgLen: numArgs withFallbackData: selector [
	| senderContext args receiver receiverClass method |
	"FIXME: Put a primitive here for a fastpath <primitive: 999>"
	senderContext := thisContext sender.
	args := Array new: numArgs.
	(1 to: numArgs) reverseDo: [ :i |
		args at: i put: senderContext pop ].
	receiver := senderContext pop.
	receiverClass := receiver class.

	method := receiverClass lookupSelector: selector.
	self assert: method notNil.

	(self nextFreeOptionAtSendSite: sendSiteIndex) ifNotNil: [ :optionIndex |
		self classAtSendsite: sendSiteIndex forOption: optionIndex put: receiverClass basicIdentityHash.
		self methodAtSendSite: sendSiteIndex forOption: optionIndex put: method ].

	^ receiver withArgs: args executeMethod: method
]

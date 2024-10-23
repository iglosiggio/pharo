Class {
	#name : 'CompiledCodeInlineCache',
	#superclass : 'ByteArray',
	#type : 'bytes',
	#category : 'Kernel-Tests-Classes',
	#package : 'Kernel-Tests',
	#tag : 'Classes'
}

{ #category : 'accessing' }
CompiledCodeInlineCache class >> arraySizeForCacheSize: aSendSiteCount [ 
	^ Smalltalk wordSize * (1 + 1 + (aSendSiteCount * self sendSiteCacheSize)).
]

{ #category : 'instance creation' }
CompiledCodeInlineCache class >> for: aCompiledCode [
	| messages wordSize cache |
	messages := aCompiledCode localMessages.
	wordSize := Smalltalk wordSize.
	
	self assert: wordSize = 8 description: '32 bit VMs are not yet supported'.

	cache := self new: (self arraySizeForCacheSize: messages size).
	cache compiledCode: aCompiledCode.
	messages withIndexDo: [ :selector :i |
		cache fallbackDataAtSendSite: i put: selector ].
	^ cache
]

{ #category : 'private' }
CompiledCodeInlineCache class >> headerByteSize [
	^ 16
]

{ #category : 'accessing' }
CompiledCodeInlineCache class >> inlinedAttempts [
	^ 3
]

{ #category : 'private' }
CompiledCodeInlineCache class >> sendSiteCacheSize [
	^ self inlinedAttempts * ( " for each attempt..."
			1 + "cached class"
			1 + "cached method"
			1 "cached native code"
		) +
		1 + "cached fallback"
		1 "cached fallback native"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> sendSiteCacheSizeInBytes [
	^ Smalltalk wordSize * self sendSiteCacheSize
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotAtSendSite: aSendSiteIndex [ 
	^ 1 + "ignored header"
		1 + "compiled code"
		((aSendSiteIndex - 1) * self sendSiteCacheSize) + "each previous send site"
		1 "this send site"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForCompiledCode [
	^ 2 "ignored header"
]

{ #category : 'private' }
CompiledCodeInlineCache class >> slotForFallbackDataAtSendSite: aSendSiteIndex [
	"see slotOffsetAtSendSite:"
	^ (self slotAtSendSite: aSendSiteIndex + 1) - 2 "Two slots from the start of the next SendSite"
]

{ #category : 'accessing' }
CompiledCodeInlineCache class >> slotForFallbackNativeAtSendSite: aSendSiteIndex [
	"see slotOffsetAtSendSite:"
	^ (self slotAtSendSite: aSendSiteIndex + 1) - 1 "One slot from the start of the next SendSite"
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
	^ (self size - self class headerByteSize) // self class sendSiteCacheSizeInBytes
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> classAtSendsite: aSendSiteIdx forOption: anOptionIdx [ 
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotAtSendSite: aSendSiteIdx.
	^ self objectAt: slot
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> classAtSendsite: aSendSiteIdx forOption: anOptionIdx put: aClass [
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotAtSendSite: aSendSiteIdx.
	^ self objectAt: slot put: aClass
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> compiledCode [
	^ self objectAt: self class slotForCompiledCode.
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> compiledCode: aCompiledCode [
	self objectAt: self class slotForCompiledCode put: aCompiledCode
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> fallbackDataAtSendSite: aSendSiteIdx [
	| slot |
	slot := self class slotForFallbackDataAtSendSite: aSendSiteIdx.
	^ self objectAt: slot
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> fallbackDataAtSendSite: aSendSiteIdx put: aFallbackDataObject [
	| slot |
	slot := self class slotForFallbackDataAtSendSite: aSendSiteIdx.
	self objectAt: slot put: aFallbackDataObject
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> fallbackNativeAtSendSite: aSendSiteIdx [
	| slot |
	self assertValidSendsite: aSendSiteIdx.
	slot := self class slotForFallbackNativeAtSendSite: aSendSiteIdx.
	^ self pointerAtSlot: slot
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> fallbackNativeAtSendSite: aSendSiteIdx put: anExternalAddress [
	| slot start |
	self assertValidSendsite: aSendSiteIdx.
	slot := self class slotForFallbackNativeAtSendSite: aSendSiteIdx.
	start := Smalltalk wordSize * (slot - 1) + 1.
	self replaceFrom: start to: start + Smalltalk wordSize - 1 with: anExternalAddress. 
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> initialize [
	| slotSize |
	slotSize := self size // Smalltalk wordSize.
	self uint64AtOffset: 0 put: (slotSize - 1 bitShift: 3) + 1.
	self objectAt: 2 put: nil.
	1 to: self cacheSize do: [ :sendSiteIdx |
		1 to: self class inlinedAttempts do: [ :optionIdx |
			self classAtSendsite: sendSiteIdx forOption: optionIdx put: nil.
			self methodAtSendSite: sendSiteIdx forOption: optionIdx put: nil.
			self nativeAtSendSite: sendSiteIdx forOption: optionIdx put: ExternalAddress null ].
		self fallbackDataAtSendSite: sendSiteIdx put: nil.
		self fallbackNativeAtSendSite: sendSiteIdx put: ExternalAddress null ]
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> methodAtSendSite: aSendSiteIdx forOption: anOptionIdx [ 
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotAtSendSite: aSendSiteIdx.
	^ self objectAt: slot + 1
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> methodAtSendSite: aSendSiteIdx forOption: anOptionIdx put: aCompiledCode [
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotAtSendSite: aSendSiteIdx.
	^ self objectAt: slot + 1 put: aCompiledCode
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> nativeAtSendSite: aSendSiteIdx forOption: anOptionIdx [ 
	| slot |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := self class slotAtSendSite: aSendSiteIdx.
	^ self pointerAtSlot: slot + 2
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> nativeAtSendSite: aSendSiteIdx forOption: anOptionIdx put: anExternalAddress [
	| slot start |
	self assertValidSendsite: aSendSiteIdx andOption: anOptionIdx.
	slot := (self class slotAtSendSite: aSendSiteIdx) + 2.
	start := Smalltalk wordSize * (slot - 1) + 1.
	self replaceFrom: start to: start + Smalltalk wordSize - 1 with: anExternalAddress. 
]

{ #category : 'accessing' }
CompiledCodeInlineCache >> objectAt: index [
	"Primitive. Answer the method header (if index=1) or a literal (if index
	>1) from the receiver. Essential. See Object documentation
	whatIsAPrimitive."

	<primitive: 68>
	self primitiveFailed
]

{ #category : 'accessing' }
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

{ #category : 'accessing' }
CompiledCodeInlineCache >> pointerAtSlot: aSlotIdx [
	^ self pointerAt: Smalltalk wordSize * (aSlotIdx - 1) + 1.
]

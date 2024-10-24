Class {
	#name : 'CompiledCodeInlineCacheTest',
	#superclass : 'TestCase',
	#category : 'Kernel-Tests-Classes',
	#package : 'Kernel-Tests',
	#tag : 'Classes'
}

{ #category : 'private' }
CompiledCodeInlineCacheTest >> methodWithTwoSendSites [
	self firstMessage.
	self secondMessage.
]

{ #category : 'tests' }
CompiledCodeInlineCacheTest >> testInitialState [
	| cache |
	cache := CompiledCodeInlineCache for: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.

	self assert: cache compiledCode equals: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.
	self assert: cache cacheSize equals: 2.
	#(firstMessage secondMessage) withIndexDo: [ :messageSelector :sendSiteIdx |
		1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
			self assert: (cache classAtSendsite: sendSiteIdx forOption: optionIdx) equals: nil.
			self assert: (cache methodAtSendSite: sendSiteIdx forOption: optionIdx) equals: nil.
			self assert: (cache nativeAtSendSite: sendSiteIdx forOption: optionIdx) equals: ExternalAddress null.
			self assert: (cache fallbackDataAtSendSite: sendSiteIdx) equals: messageSelector.
			self assert: (cache fallbackNativeAtSendSite: sendSiteIdx) equals: ExternalAddress null ] ].
]

{ #category : 'tests' }
CompiledCodeInlineCacheTest >> testModifyFirstSendsite [
	| cache |
	cache := CompiledCodeInlineCache for: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.

	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		cache classAtSendsite: 1 forOption: optionIdx put: 'class', optionIdx asString.
		cache methodAtSendSite: 1 forOption: optionIdx put: 'method', optionIdx asString.
		cache nativeAtSendSite: 1 forOption: optionIdx put: (ExternalAddress fromAddress: optionIdx) ].
	cache fallbackDataAtSendSite: 1 put: #newValue.
	cache fallbackNativeAtSendSite: 1 put: (ExternalAddress fromAddress: 16rFAFAFA).

	"CompiledCode stays the same"
	self assert: cache compiledCode equals: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.

	"First sendsite was modified"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 1 forOption: optionIdx) equals: 'class', optionIdx asString.
		self assert: (cache methodAtSendSite: 1 forOption: optionIdx) equals: 'method', optionIdx asString.
		self assert: (cache nativeAtSendSite: 1 forOption: optionIdx) equals: (ExternalAddress fromAddress: optionIdx).
		self assert: (cache fallbackDataAtSendSite: 1) equals: #newValue.
		self assert: (cache fallbackNativeAtSendSite: 1) equals: (ExternalAddress fromAddress: 16rFAFAFA) ].

	"Second sendsite stays the same"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 2 forOption: optionIdx) equals: nil.
		self assert: (cache methodAtSendSite: 2 forOption: optionIdx) equals: nil.
		self assert: (cache nativeAtSendSite: 2 forOption: optionIdx) equals: ExternalAddress null.
		self assert: (cache fallbackDataAtSendSite: 2) equals: #secondMessage.
		self assert: (cache fallbackNativeAtSendSite: 2) equals: ExternalAddress null ].
]

{ #category : 'tests' }
CompiledCodeInlineCacheTest >> testModifyScoundSendsite [
	| cache |
	cache := CompiledCodeInlineCache for: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.

	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		cache classAtSendsite: 2 forOption: optionIdx put: 'class', optionIdx asString.
		cache methodAtSendSite: 2 forOption: optionIdx put: 'method', optionIdx asString.
		cache nativeAtSendSite: 2 forOption: optionIdx put: (ExternalAddress fromAddress: optionIdx) ].
	cache fallbackDataAtSendSite: 2 put: #newValue.
	cache fallbackNativeAtSendSite: 2 put: (ExternalAddress fromAddress: 16rFAFAFA).

	"CompiledCode stays the same"
	self assert: cache compiledCode equals: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.

	"First sendsite stays the same"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 1 forOption: optionIdx) equals: nil.
		self assert: (cache methodAtSendSite: 1 forOption: optionIdx) equals: nil.
		self assert: (cache nativeAtSendSite: 1 forOption: optionIdx) equals: ExternalAddress null.
		self assert: (cache fallbackDataAtSendSite: 1) equals: #firstMessage.
		self assert: (cache fallbackNativeAtSendSite: 1) equals: ExternalAddress null ].

	"Second sendsite was modified"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 2 forOption: optionIdx) equals: 'class', optionIdx asString.
		self assert: (cache methodAtSendSite: 2 forOption: optionIdx) equals: 'method', optionIdx asString.
		self assert: (cache nativeAtSendSite: 2 forOption: optionIdx) equals: (ExternalAddress fromAddress: optionIdx).
		self assert: (cache fallbackDataAtSendSite: 2) equals: #newValue.
		self assert: (cache fallbackNativeAtSendSite: 2) equals: (ExternalAddress fromAddress: 16rFAFAFA) ].
]

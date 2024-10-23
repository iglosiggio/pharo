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

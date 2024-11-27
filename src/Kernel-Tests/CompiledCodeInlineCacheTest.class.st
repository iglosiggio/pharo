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
CompiledCodeInlineCacheTest >> testCreateFromMethod [
	| cache fallbackData |
	cache := CompiledCodeInlineCache for: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.
	fallbackData := {
		cache fallbackDataAtSendSite: 1.
		cache fallbackDataAtSendSite: 2.
	}.

	self assert: cache compiledCode equals: CompiledCodeInlineCacheTest>>#methodWithTwoSendSites.
	self assert: cache cacheSize equals: 2.
	self assertCollection: fallbackData hasSameElements: #(firstMessage secondMessage)
]

{ #category : 'tests' }
CompiledCodeInlineCacheTest >> testInitialState [
	| cache |
	cache := CompiledCodeInlineCache forSendsites: #(firstMessage secondMessage).

	#(firstMessage secondMessage) withIndexDo: [ :messageSelector :sendSiteIdx |
		1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
			self assert: (cache classAtSendsite: sendSiteIdx forOption: optionIdx) equals: nil.
			self assert: (cache methodAtSendSite: sendSiteIdx forOption: optionIdx) equals: nil ].
		self assert: (cache fallbackDataAtSendSite: sendSiteIdx) equals: messageSelector.
		self assert: (cache fallbackMethodAtSendSite: sendSiteIdx) equals: nil ].
]

{ #category : 'tests' }
CompiledCodeInlineCacheTest >> testModifyFirstSendsite [
	| cache |
	cache := CompiledCodeInlineCache forSendsites: #(firstMessage secondMessage).

	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		cache classAtSendsite: 1 forOption: optionIdx put: 'class', optionIdx asString.
		cache methodAtSendSite: 1 forOption: optionIdx put: 'method', optionIdx asString ].
	cache fallbackDataAtSendSite: 1 put: #newValue.
	cache fallbackMethodAtSendSite: 1 put: Behavior>>#lookupSelector:.

	"First sendsite was modified"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 1 forOption: optionIdx) equals: 'class', optionIdx asString.
		self assert: (cache methodAtSendSite: 1 forOption: optionIdx) equals: 'method', optionIdx asString ].
	self assert: (cache fallbackDataAtSendSite: 1) equals: #newValue.
	self assert: (cache fallbackMethodAtSendSite: 1) equals: Behavior>>#lookupSelector:.

	"Second sendsite stays the same"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 2 forOption: optionIdx) equals: nil.
		self assert: (cache methodAtSendSite: 2 forOption: optionIdx) equals: nil ].
	self assert: (cache fallbackDataAtSendSite: 2) equals: #secondMessage.
	self assert: (cache fallbackMethodAtSendSite: 2) equals: nil
]

{ #category : 'tests' }
CompiledCodeInlineCacheTest >> testModifySecondSendsite [
	| cache |
	cache := CompiledCodeInlineCache forSendsites: #(firstMessage secondMessage).

	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		cache classAtSendsite: 2 forOption: optionIdx put: 'class', optionIdx asString.
		cache methodAtSendSite: 2 forOption: optionIdx put: 'method', optionIdx asString ].
	cache fallbackDataAtSendSite: 2 put: #newValue.
	cache fallbackMethodAtSendSite: 2 put: Behavior>>#lookupSelector:.

	"CompiledCode stays the same"
	self assert: cache compiledCode equals: nil.

	"First sendsite stays the same"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 1 forOption: optionIdx) equals: nil.
		self assert: (cache methodAtSendSite: 1 forOption: optionIdx) equals: nil ].
	self assert: (cache fallbackDataAtSendSite: 1) equals: #firstMessage.
	self assert: (cache fallbackMethodAtSendSite: 1) equals: nil. 

	"Second sendsite was modified"
	1 to: CompiledCodeInlineCache inlinedAttempts do: [ :optionIdx |
		self assert: (cache classAtSendsite: 2 forOption: optionIdx) equals: 'class', optionIdx asString.
		self assert: (cache methodAtSendSite: 2 forOption: optionIdx) equals: 'method', optionIdx asString ].
	self assert: (cache fallbackDataAtSendSite: 2) equals: #newValue.
	self assert: (cache fallbackMethodAtSendSite: 2) equals: Behavior>>#lookupSelector:
]

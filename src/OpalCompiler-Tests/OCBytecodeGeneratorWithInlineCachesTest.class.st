Class {
	#name : 'OCBytecodeGeneratorWithInlineCachesTest',
	#superclass : 'TestCase',
	#category : 'OpalCompiler-Tests-Bytecode',
	#package : 'OpalCompiler-Tests',
	#tag : 'Bytecode'
}

{ #category : 'helper' }
OCBytecodeGeneratorWithInlineCachesTest >> for: selector build: aClosure [
	| generator |
	generator := (IRBytecodeGeneratorWithInlineCaches newWithEncoderClass: EncoderForSistaV1)
		compilationContext: CompilationContext new;
		numArgs: selector numArgs;
		yourself.
	aClosure value: generator.
	^ generator compiledMethod
		methodClass: self class;
		selector: selector;
		yourself.
]

{ #category : 'tests' }
OCBytecodeGeneratorWithInlineCachesTest >> testBytecodeGeneratorCreatesInlineCache [
	| compiledMethod inlineCache |
	compiledMethod := self for: #test build: [ :aBuilder |
		aBuilder numTemps: 0;
			pushReceiver;
			send: #class;
			send: #class;
			send: #allSubclasses;
			returnTop ].
	inlineCache := compiledMethod literalAt: 1.

	self assert: (inlineCache isKindOf: CompiledCodeInlineCache).
	self assert: (inlineCache cacheSize) equals: 3.
	self assert: (inlineCache compiledCode) equals: compiledMethod
]

{ #category : 'tests' }
OCBytecodeGeneratorWithInlineCachesTest >> testBytecodeGeneratorSendsitesHaveIndices [
	| compiledMethod inlineCache |
	compiledMethod := self for: #test build: [ :aBuilder |
		aBuilder numTemps: 0;
			pushReceiver;
			send: #class;
			send: #class;
			send: #allSubclasses;
			returnTop ].
	inlineCache := compiledMethod literalAt: 1.

	compiledMethod literals withIndexDo: [ :literal :idx |
		literal isSymbol ifTrue: [ 
			| sendsiteIdx fallbackData |
			sendsiteIdx := compiledMethod literalAt: idx + 1.
			fallbackData := inlineCache fallbackDataAtSendSite: sendsiteIdx.
			self assert: literal equals: fallbackData. ] ]

	"FIXME: This test asks too much of the bytecode generator, we should probably do something like:
		compiledMethod sendsites do: [ :sendSite |
			| fallbackData |
			fallbackData := inlineCache fallbackDataAtSendSite: sendsite index.
			self assert: sendsite selector equals: fallbackData ]"
]

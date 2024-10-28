Class {
	#name : 'IRBytecodeGeneratorWithInlineCaches',
	#superclass : 'IRBytecodeGenerator',
	#category : 'OpalCompiler-Core-Bytecode',
	#package : 'OpalCompiler-Core',
	#tag : 'Bytecode'
}

{ #category : 'initialization' }
IRBytecodeGeneratorWithInlineCaches >> initialize [
	super initialize.

	literals addLiteral: Object new. "reserve first slot for inline caches"
]

{ #category : 'initialization' }
IRBytecodeGeneratorWithInlineCaches >> irPrimitive: anIrPrimitive [
	anIrPrimitive spec ifNotNil: [self error: 'external primitives are not yet supported'].
	primNumber := anIrPrimitive num.
	primNumber = 0 ifTrue: [ ^ self ].
	self encoderClass callPrimitiveCode ifNil: [ ^ self ].
	encoder genCallPrimitive: primNumber
]

{ #category : 'results' }
IRBytecodeGeneratorWithInlineCaches >> literals [
	| inlineCaches |

	inlineCaches := CompiledCodeInlineCache forSendsites: literals messageSends.

	^ super literals
		at: 1 put: inlineCaches;
		yourself.
]

{ #category : 'private' }
IRBytecodeGeneratorWithInlineCaches >> methodSelectorIndexOf: object [
	| index |
	index := literals addMessageSelector: object.
	"conversion from 1 based to 0 based"
	^ index - 1
]

{ #category : 'results' }
IRBytecodeGeneratorWithInlineCaches >> spurVMHeader: literalsSize [
	^ (super spurVMHeader: literalsSize) +
		(1 bitShift: 29) "Flag for inline caches"
]

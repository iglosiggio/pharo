Class {
	#name : 'OpalCompilerWithInlineCaches',
	#superclass : 'OpalCompiler',
	#category : 'OpalCompiler-Core-FrontEnd',
	#package : 'OpalCompiler-Core',
	#tag : 'FrontEnd'
}

{ #category : 'accessing' }
OpalCompilerWithInlineCaches >> compilationContext [
	^ compilationContext ifNil: [
		compilationContext := self compilationContextClass default
			bytecodeGeneratorClass: IRBytecodeGeneratorWithInlineCaches;
			yourself ]
]

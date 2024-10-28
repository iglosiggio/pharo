"
Holds a unique ordered collection of literals.
I uses an special dictionary inside that compares literals using #literalEquals message.
I am optimised to guarantee that literals all unique and have an unique index.
"
Class {
	#name : 'OCLiteralList',
	#superclass : 'Object',
	#instVars : [
		'literalsDict',
		'first',
		'messageSends'
	],
	#category : 'OpalCompiler-Core-Extras',
	#package : 'OpalCompiler-Core',
	#tag : 'Extras'
}

{ #category : 'adding' }
OCLiteralList >> addLiteral: anObject [
	| index |
	index := self arraySize + 1.

	"I keep the first element, so it can be easily returned"
	index = 1 ifTrue: [ first := anObject ].

	^ literalsDict at: anObject ifAbsentPut: index
]

{ #category : 'adding' }
OCLiteralList >> addMessageSelector: selector [
	| index |
	index := self arraySize + 1.

	"I keep the first element, so it can be easily returned"
	index = 1 ifTrue: [ first := selector ].

	messageSends add: selector -> index.
	^ index
]

{ #category : 'private' }
OCLiteralList >> arraySize [
	^ messageSends size * 2 + literalsDict size
]

{ #category : 'converting' }
OCLiteralList >> asArray [

	| result |

	result := Array new: self arraySize.

	literalsDict associationsDo: [ :anAssoc | result at: anAssoc value put: anAssoc key ].
	messageSends withIndexDo: [ :anAssoc :sendSiteIdx |
		result at: anAssoc value put: anAssoc key.
		result at: anAssoc value + 1 put: sendSiteIdx ].

	^ result
]

{ #category : 'adding' }
OCLiteralList >> first [

	^ first
]

{ #category : 'initialization' }
OCLiteralList >> initialize [

	super initialize.
	literalsDict := OCLiteralDictionary new.
	messageSends := OrderedCollection new.
]

{ #category : 'testing' }
OCLiteralList >> isEmpty [

	^ literalsDict isEmpty
]

{ #category : 'accessing' }
OCLiteralList >> literalIndexOf: anElement ifAbsent: exceptionBlock [

	^ literalsDict at: anElement ifAbsent: exceptionBlock
]

{ #category : 'accessing' }
OCLiteralList >> messageSends [
	^ messageSends
]

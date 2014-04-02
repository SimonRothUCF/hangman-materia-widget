###

Materia
It's a thing

Widget  : Hangman, Creator
Authors : Jonathan Warner, Micheal Parks, Brandon Stull
Updated : 4/14

###

# Create an angular module to import the animation module and house our controller.
Hangman = angular.module 'HangmanCreator', ['ngAnimate', 'ngSanitize', 'hammer']

Hangman.factory 'Resource', ['$sanitize', ($sanitize) ->
	buildQset: (title, items, partial, attempts) ->
		qsetItems = []
		qset = {}

		# Decide if it is ok to save.
		if title is ''
			Materia.CreatorCore.cancelSave 'Please enter a title.'
			return false
		else
			for i in [0..items.length-1]
				if items[i].ans.length > 34
					Materia.CreatorCore.cancelSave 'Please reduce the number of characters in word #'+(i+1)+'.'
					return false
				# letters, numbers, spaces, periods, commas, dashes and underscores only
				# prevent characters from being used that cannot be input by the user
				if not /^[\w\s\.\,\-\_]*$/.test(items[i].ans)
					Materia.CreatorCore.cancelSave 'Word #'+(i+1)+' should contain only letters or numbers.'
					return false

		qset.options = {partial: partial, attempts: attempts}
		qset.assets = []
		qset.rand = false
		qset.name = title

		for i in [0..items.length-1]
			item = @processQsetItem items[i]
			qsetItems.push item if item
		qset.items = [{items: qsetItems}]

		qset

	processQsetItem: (item) ->
		return false if item.ans == ''

		item.ques = item.ques
		item.ans = item.ans

		qsetItem = {}
		qsetItem.assets = []

		qsetItem.materiaType = "question"
		qsetItem.id = ""
		qsetItem.type = 'QA'
		qsetItem.questions = [{text : item.ques}]
		qsetItem.answers = [{value : '100', text : item.ans}]

		qsetItem

	# IE8/IE9 are super special and need this
	placeholderPolyfill: () ->
		$('[placeholder]')
		.focus ->
			if this.value is this.placeholder
				this.value = ''
				this.className = ''
		.blur ->
			if this.value is '' or this.value is this.placeholder
				this.className = 'placeholder'
				this.value = this.placeholder

		$('form').submit ->
			$(this).find('[placeholder]').each ->
				if this.value is this.placeholder then this.value = ''
]

# Set the controller for the scope of the document body.
Hangman.controller 'HangmanCreatorCtrl', ['$scope', '$sanitize', 'Resource',
($scope, $sanitize, Resource) ->
	$scope.title = "My Hangman widget"
	$scope.items = []
	$scope.partial = false
	$scope.attempts = 5

	$scope.updateForBoard = (item) ->
		item.answer = $scope.forBoard(item.ans.toString())

	$scope.forBoard = (ans) ->
		# Question-specific data
		dashes = []
		guessed = []
		answer = []

		# This parsing is only necessary for multi-row answers
		if ans.length >= 13
			ans = ans.split ' '
			i = 0
			while i < ans.length
				# Add as many words as we can to a row
				j = i
				while ans[i+1]? and ans[i].length + ans[i+1].length < 12
					temp = ans.slice i+1, i+2
					ans.splice i+1, 1
					ans[i] += ' '+temp
				# Check to see if a word is too long for a row
				if ans[i]? and ans[i].length > 12
					temp = ans[i].slice 11, ans[i].length
					ans[i] = ans[i].substr 0, 11
					dashes[i] = true
					ans.push()
					ans[i+1] = temp+' '+ if ans[i+1]? then ans[i+1] else ''
				i++

			if ans.length > 3
				# we're out of bounds on the board and should cram things in there
				i = 0
				while i < ans.length
					# Add as many words as we can to a row
					j = i
					temp = ans.slice i+1, i+2
					ans.splice i+1, 1
					ans[i] += ' '+temp
					# Check to see if a word is too long for a row
					if ans[i]? and ans[i].length > 12
						temp = ans[i].slice 11, ans[i].length
						ans[i] = ans[i].substr 0, 11
						dashes[i] = true
						ans.push()
						ans[i+1] = temp+' '+ if ans[i+1]? then ans[i+1] else ''
					i++

		else
			# If the answer wasn't split then insert it into a row
			ans = [ans]

		# Now that the answer string is ready, data-bind it to the DOM
		for i in [0..ans.length-1]
			guessed.push []
			answer.push []
			for j in [0..ans[i].length-1]
				# Pre-fill punctuation or spaces so that the DOM shows them
				if ans[i][j] is ' ' or ans[i][j].match /[\.,-\/#!?$%\^&\*;:{}=\-_`~()']/g
					guessed[i].push ans[i][j]
				else
					guessed[i].push ''
				answer[i].push {letter: ans[i][j]}

		# Return the parsed answer's relevant data
		{dashes:dashes, guessed:guessed, string:answer}

	$scope.changeTitle = ->
		$('#backgroundcover, .title').addClass 'show'
		$('.title input[type=text]').focus()
		$('.title input[type=button]').click ->
			$('#backgroundcover, .title').removeClass 'show'

	$scope.initNewWidget = (widget, baseUrl) ->
		return

		$('#backgroundcover, .intro').addClass 'show'

		$('.intro input[type=button]').click ->
			$('#backgroundcover, .intro').removeClass 'show'
			$scope.$apply ->
				$scope.title = $('.intro input[type=text]').val() or $scope.title
				$scope.step = 1

		if not Modernizr.input.placeholder then Resource.placeholderPolyfill()

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		$scope.title = title
		$scope.attempts = qset.options.attempts
		$scope.partial = qset.options.partial
		$scope.onQuestionImportComplete qset.items[0].items

		$scope.$apply()
		if not Modernizr.input.placeholder then Resource.placeholderPolyfill()

	$scope.onSaveClicked = (mode = 'save') ->
		qset = Resource.buildQset $sanitize($scope.title), $scope.items, $scope.partial, $scope.attempts
		if qset then Materia.CreatorCore.save $sanitize($scope.title), qset

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	$scope.onQuestionImportComplete = (items) ->
		$scope.addItem items[i].questions[0].text, items[i].answers[0].text for i in [0..items.length-1]
		$scope.$apply()

	$scope.onMediaImportComplete = (media) -> true

	$scope.addItem = (ques = "", ans = "") ->
		$scope.items.push {ques:ques, ans:ans, foc:false}

	$scope.removeItem = (index) ->
		$scope.items.splice index, 1

	$scope.setAttempts = (num) ->
		$scope.attempts = num

	$scope.setPartial = (bool) ->
		$scope.partial = bool
	
	$scope.editItem = (item,index) ->
		item.editing = true
		setTimeout ->
			$('#tarea_'+index).focus()
		,10
]

# Load Materia Dependencies
require ['creatorcore'], (util) ->
	# Pass Materia the scope of our start method
	Materia.CreatorCore.start angular.element($('body')).scope()

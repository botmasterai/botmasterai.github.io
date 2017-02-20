---
date: 2017-02-19T11:56:16Z
next: /watson-conversation
prev: /tutorials
title: Using Botmaster Fulfill Middleware
toc: true
weight: 10
---

<!-- TOC depthFrom:1 depthTo:2 withLinks:1 updateOnSave:1 orderedList:0 -->
<!-- /TOC -->


# Using Botmaster Fulfill middleware

Although many of you will be using Botmaster because of its ability to connect with message sources like Facebook Messenger, it also has a powerful middleware called Botmaster Fulfill. Fulfill helps helps greatly with building more sophisticated bots that need integrations with external data sources and more complex logic. It’s task is to provide a framework for addressing tasks that are outside of the scope of a core NLU or AI engine, so it’s complementary to something like Watson Conversation or Wit.ai.

## What can I do with Botmaster Fulfill?
You hopefully want to wow your bot’s users with some high-end functionality that gets them hooked on using a conversational interface to get stuff done. If so, you will need to rely on more than pre-canned static replies held within your AI engine – such bots can get pretty boring quite quickly.

Connecting your bot to more dynamic and real-time sources of information is probably high on your priority list. In addition, taking advantage of UI features like buttons and location awareness, might also be things you are interested in. These are the kind of things that Botmaster Fulfill can help with.

To get specific, here is a set of things that you might use Botmaster Fulfill for:

- Specifying where various types of buttons might be used within the conversation to guide the user’s response.
- Specifying how a longer conversational response should be broken into a series of shorter messages that appear one-after-the-other in the user’s messaging app, just like we tend to do when texting a friend.
- Calling external API services and integrating the results into the conversation, for example adding a stock quote or weather forecast. Or a call to your organisation’s core systems to retrieve a customer order or balance.
- Initiating transactions such as placing an order or making a payment.
- Making a time-of-day specific greetings (Good morning, Good afternoon, Good evening, etc).

In short, anything you need your bot to do that your AI doesn’t, is probably a candidate for Botmast Fulfill.

## Why should I use Botmaster Fulfill?
“Separation of concerns” is generally considered a good thing. It turns out that in bot design, it’s an especially good thing. Why do we say that?

Designing your conversational flow and how your bot responds to questions is an analyst-type job - you need people good at understanding the problem domain and how to craft a great conversations. You these people to have a nice life, unencumbered by any technical complexities.

If your bot needs to invoke programming logic, for example to call an external API and include the results into the bot’s response, you surely want to keep that programming away from your conversational analysts.

However, before Botmaster Fulfill it was tricky to keep your conversational design totally separate from your integration logic. Or sometimes you ended up with small pieces of logic buried in your conversational flow who flagged things to some external integration logic - which is basically unmaintainable in the long term.

Botmaster Fulfill solves these problems by providing a clean separation of concerns.  With it, conversational analysts use simple XML tags to markup a bot’s responses. Those tags are interpreted by a series of javascript modules that implement the logic needed. The conversational analyst gets to specify when logic should be called and the engineer gets to separately specify how that logic is implemented….and we achieve a separation of concerns.

## How do I use Fulfill in my conversational flow?
The beauty of Botmaster Fulfill is that complex logic can be specified by including very simple XML tags within a bot’s response text. For example, in the following dialog response the <weather /> tag is identified by Botmaster Fulfill and replaced with the result of an API call to a weather forecast service.
`I thought you might like a weather forecaset, so here it is: <weather />`

What is super nice here, is that your dialog designer doesn’t need to worry about how the weather API works or indeed how to get the result of that API call into her conversational response. That’s the engineer’s job - which we will come to shortly.

Here’s another, more complex, example:

```
<greet /><pause />How are you today?<buttons>Good,Bad,Indifferent</buttons>
```

This results in two separate messages being sent:

1. A message that’s reflective of the time of day, such as “Good morning!” or “Good afternoon.”
2. A second message “How are you today?” with three quick-reply buttons Good, Bad, Indifferent.

As you can hopefully see, multiple XML tags can be included within the same response, building some quite sophisticated responses and integrations. It’s super-simple for the conversational analyst to specify these tags and the programming logic to implement them is totally separated.

## Sounds great, how do I get started?
The implementation of the logic needed to fulfil these XML tags is through what we call a Botmaster Fulfill action. These actions are really just standard javascript code, so any half-decent node coder should be able to get to grips with things pretty quickly.

But to get us going, we’re first going to use some pre-defined Botmaster Fulfill actions. We’ll move on to making our own custom actions in the next step.

First of all install Botmaster Fulfill using: `npm install botmaster-fulfill -S`

Then, install the pre-defined Botmaster Fulfill actions using: `npm install botmaster-fulfill-actions -S`

Now add the following code to your Botmaster `app.js` file:

```js
const {fulfillOutgoingWare} = require('botmaster-fulfill');
const actions = require('botmaster-fulfill-actions');
botmaster.use('outgoing', fulfillOutgoingWare({
    actions
}));
```

Now we’re ready to go! At the time of writing, the standard actions include:

 - `<pause />` - which breaks the message into two separate messages, one from each side of the pause tag.
 - `<greet tz="Europe/London" />` - which returns a location/language relevant greeting such as “Good morning” or “Good evening”, depending on the time of day and the timezone/location specified.

Go ahead and try these out by adding something like the following as a response in whatever dialoging engine you are using:
`<greet /><pause />How are you today?`

If you haven’t wired up an AI engine yet, you could just add the following code to your app.js file. If you do that, it doesn’t matter what you type into your bot, you’ll get the same answer - but it does the job of exercising Botmaster Fulfill and its standard actions.

```js
botmaster.on('update', (bot, update) => {
	bot.reply(update, '<greet /><pause />How are you today?');
}
```

How cool is that?! The Botmaster project is hoping to expand this set of standard actions, so keep an eye on the Github repo.

## But how do I write my own Botmaster Fulfill actions?
As we discussed earlier, Botmaster Fulfill actions are just javascript – so, as you’re already using Botmaster, you will already be at least vaguely competent at this task. It’s OK if you’re still at the vague end of the competency spectrum - you can write simple Actions with very basic knowledge.

Lets start off by modifying our above code with a super-simple custom action. To do this, we define our custom action by adding the following code after the definition of standardActions in the `app.js` we used in the last step.

```js
const checkUserState = {
	controller: function(params) {
		return new Promise(function(resolve, reject) {
			resolve('How are you today?');
		});
	}
};
```

This is pretty self-explanatory – checkUserState is the name of the XML tag this code implements. The variable `params` is just a placeholder for whatever text might be between the open and closing XML tags. In our case this will be empty, because we have a single open/close tag. We return a Javascript Promise that resoles to “How are you today?”, the text that replaces our checkUserState tag in the bot’s reply. Returning a Promise means our code is executed asynchronously - which is pretty handy if you’re calling an external API, for example.

Next, we need to modify our `botmaster.use` statement to include `checkUserState` as follows:

```js
actions.checkUserState = checkUserState;
botmaster.use('outgoing', fulfillOutgoingWare({
	actions
}));
```

And change our bot reply text to something like the following:
`<greet /><pause /><checkUserState />`

Now this might not be the best of example - it’s a bit overkill to implement a simple question as a Fulfill Action. However, it’s often good to start with something basic so as not to overwhelm ourselves. And “Hello World” has become a bit too ubiquitous for my liking.

## Using Fulfill to create Quick Reply Buttons
As we’ve asked a question at this point, wouldn’t it be kind of cool if we provided a `Yes` and `No` Quick Reply button as a response? Luckily this is pretty easy to do with Botmaster’s Quick Reply functionality in partnership with Botmaster Fulfill.

To do this we can add the following Botmaster Fulfill action for buttons:

```js
buttons: {
	controller: (params) => {
		const buttonTitles = params.content.split('|');
			params.update.message.quick_replies = [];
			for (const buttonTitle of buttonTitles) {
				params.update.message.quick_replies.push({
					content_type: 'text',
					title: buttonTitle,
					payload: buttonTitle,
				});
			}
			return '';
		},
	},
},
```

And update our reply to be:
`<helloWorld /><pause /><checkUserState /><buttons>Yes|No</buttons>`

Do you see what we’re doing here? The button titles are included between the opening/closing <buttons> tags and separated by “|“. Our controller receives this in the `paramas` object and splits its contents apart to create a Botmaster quick replies array. You can hopefully see how you might use the same principle to create other types of Botmaster reply objects.

## Finding the user’s location
If the user is using Facebook Messenger, we can extend the above example to generate a special button asking for the user’s location, which results in us receiving the user’s latitude/longitude.

```js
locButton: {
	controller: (params) => {
		params.update.message.quick_replies = [];
		params.update.message.quick_replies.push({
		content_type: 'location',
	});
	return '';
	},
},
```

and change the returned text to:

```js
botmaster.on('update', (bot, update) => {
	if (update.message.text != ('Good' || 'Bad' || 'Indifferent')) {
		bot.reply(update, '<greet tz="Europe/London" /> <userName /><pause />How are you today?<pause /><buttons>Good,Bad,Indifferent</buttons>');
	} else {
		bot.reply(update, 'OK. It would be interesting to know where you are.<pause /><locButton />');
	}
});
```

So now we have a message returned to us that has the user’s location embedded within in it. How about we use that latitude/longitude to get a weather forecast using a Fulfill action and return that to the user?

## Calling an external API in a Fulfill Action
So far our examples have been quite trivial. But Fulfill can do some pretty sophisticated things. One thing we find particularly useful is the ability to call an external API and integrate it’s results into the conversational response.

For this exercise we’re going to integrate the results of a weather forecast API call into our bot’s response.

Here’s the function that calls the weather API service. You’ll need to register [here](https://console.ng.bluemix.net/catalog/services/weather-company-data/) in Bluemix and provide the required userID and password fields to make it work.

```js
function getWeather(params) {
	const lat = params.content.split(',')[0];
	const long = params.content.split(',')[1];
	const requestOptions = {
		url: 'https://twcservice.mybluemix.net/api/weather/v1/geocode/' + lat + '/' + long + '/forecast/daily/3day.json?language=en-US&units=e',
		auth: {
			user: '[enter user-id here]',
			pass: '[enter password here]',
			sendImmediately: true,
		},
		json: true,
	};
	return request(requestOptions)
	.then((body) => body.forecasts[0].narrative);
}
```

And here’s our weather Action definition:

```js
weather: {
	controller: function(params) {
		return getWeather(params)
		.then(function(result) {
			console.log(result);
			return 'I thought you might like a weather forecast for that location.<pause />' + result;
		})
		.catch(function(err) {
			console.log(err);
			return 'Sorry, no weather forecast available at the moment.';
		});
	}
},
```

If we update our bot message return logic to the following, we should be able to get a weather forecast sent back to the user when they click on one of the Good, Bad, Indifferent buttons:

```js
botmaster.on('update', (bot, update) => {
	if (typeof update.message.attachments != 'undefined') {
		if (update.message.attachments[0].type == 'location') {
			const lat = update.message.attachments[0].payload.coordinates.lat;
			const long = update.message.attachments[0].payload.coordinates.long;
			bot.reply(update, '<weather>' + lat + ',' + long + '</weather>');
		}
	}
	else {
		if (update.message.text != ('Good' || 'Bad' || 'Indifferent')) {
			bot.reply(update, '<greet tz="Europe/London" /> <userName /><pause />How are you today?<pause /><buttons>Good,Bad,Indifferent</buttons>');
		} else {
			bot.reply(update, 'OK. It would be interesting to know where you are.<pause /><locButton />');
		}
	}
});
```

So there you have it. Using Botmaster Fulfill to execute standard actions that generate a greeting and break messages up. Using Botmaster Fulfill to generate quick reply buttons, get the user’s location and then call an external weather forecast API. Hopefully your scenario is similar to at least one of these examples and you can find a way of using Fulfill to separate the concerns of your developer and conversational analyst.

If you want to just skip to a working version of this tutorial, just download [this](app.js) pre-built `app.js` file.

If you're inspired by this tutorial to develop your own actions, please consider submitting them to the Botmaster community through a `Pull` request. We want to foster the development of a library of these functions to simplify everyone’s jobs - and you can help!

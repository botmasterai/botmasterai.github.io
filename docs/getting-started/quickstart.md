# Quickstart

In this quickstart tutorial, you'll learn how to quickly get a simple Botmaster project up and running.
The bot will work on both the Facebook Messenger and Twitter (DMs) platforms. Support for other platforms can be added
very easily as will be described later.

Because we only want to get acquainted with Botmaster, we'll build a very naive and simple bot that doesn't really do much. i.e. with no support for natural language processing, conversational flows etc... We just want to expose how botmaster works here.

It'll look something like this on Facebook Messenger:

![Quickstart 1](/images/quickstart_1.png?width=50%)

And like this on Twitter (DMs):

![Quickstart 2](/images/quickstart_2.png?width=50%)

This mini-tutorial assumes that you have already installed botmaster as documented in the installation guide: [here](/getting-started/installation).

## Step 1: Setup

In the folder in which you installed botmaster, create an `app.js` file and put the following lines in it:

```js
const Botmaster = require('botmaster');

const botmaster = new Botmaster();
```

Nothing special is going on here. We're just requiring the Botmaster class (exposed via the botmaster package) and creating a new instance of Botmaster.

Now, in order for Botmaster to manage out bots, we obviously need to create at least one bot. We'll go on and create couple. One Facebook Messenger bot and one Twitter DM bot.

>To complete the following steps, you will need to gather valid credentials for the platforms you want to use. Read the following small guides for Facebook Messenger and Twitter DMs if you don't have credentials for these platforms yet:
[messenger](/getting-started/messenger-setup), [twitter](/getting-started/twitter-setup). Other guides are also available in this getting-started section.


```js
const MessengerBot = Botmaster.botTypes.MessengerBot;
const TwitterBot = Botmaster.botTypes.TwitterBot;

const messengerSettings = {
  credentials: {
    verifyToken: 'YOUR verifyToken',
    pageToken: 'YOUR pageToken',
    fbAppSecret: 'YOUR fbAppSecret',
  },
  webhookEndpoint: '/webhook1234', // botmaster will mount this webhook on https://Your_Domain_Name/messenger/webhook1234
};

const twitterSettings = {
  credentials: {
    consumerKey: 'YOUR consumerKey',
    consumerSecret: 'YOUR consumerSecret',
    accessToken: 'YOUR accessToken',
    accessTokenSecret: 'YOUR accessTokenSecret',
  }
}

const messengerBot = new MessengerBot(messengerSettings);
const twitterBot = new TwitterBot(twitterSettings);
```

There seems to be quite a bit going on here. Let's look at it all line by line:

On the first two lines we get the `MessengerBot` and `TwitterBot` classes exposed via Botmaster. The Botmaster package comes bundled in with 5 bot classes so that you can get started straight away. They are all exposed via: `Botmaster.botTypes`, where `Botmaster` is gotten via `const Botmaster = require('botmaster');`

Next, settings objets for both platforms are created: namely the `messengerSettings` and `twitterSettings` objects. To see how to gather the necessary credentials, have a look at these small guides: [messenger](/getting-started/messenger-setup), [twitter](/getting-started/twitter-setup).

In the `messengerSettings` object, the `webhookEndpoint` parameter simply indicates to Botmaster what endpoint we want the Facebook Messenger messages to come into. I.e. if you host your Botmaster app on, say, "https://somebotmasterapp.com", Messages coming in from Facebook Messenger will hit: "https://somebotmasterapp.com/messenger/webhook1234". This works because Botmaster is built on top of express.js. Read more about webhooks and how to make them work locally [here](/getting-started/webhooks).

As it stands, these bot objects don't really have much to do with our previously create botmaster one. We want to be able to manage them from the botmaster obejct. So we will now add (or mount) these newly created bot objects onto the botmaster object we created previously. So right after these few lines, enter the following:

```js
botmaster.addBot(messengerBot);
botmaster.addBot(twitterBot);
```

These lines simply indicate to botmaster that it should be notified of all activity going on within our two bot objects. But still, botmaster doesn't actually do anything yet. let's change this!

## Step 2: listening to events

In order for botmaster to be notified of any activity going on (i.e. users sending messages to your bots), we'll need to listen to the 'update' event that fires whenever a user sends a message to one of our bots. It looks like this:

```js
botmaster.on('update', (bot, update) => {
  console.log(update, null, 2);
});
```

>You should ever only have one `.on('update',...)` listener by botmaster app, as events are asynchronous in nature and having multiple ones will result in unforeseen occurrences.

At this point, whenever a message (or update in Botmaster semantic) is received by any of your bots, you will be printing to the console the received message. You'll also note that the callback function has a `bot` object associated with it. This object will be either of `messengerBot` or `twitterBot` in this example depending on what bot actually received the update

This is great. But what if I want to send something back to the user. Well, let's have a look.

## Step 3: sending replies

The easiest thing to do to have a bot that answers you is the following; replace the Step 2 code with this:

```js
botmaster.on('update', (bot, update) => {
  bot.reply(update, 'Hello World!');
});
```

This really doesn't do much however. Let's try to get to something like what we saw in the pictures at the beginning of this tutorial. Let's replace this code with this:

```js
botmaster.on('update', (bot, update) => {
  if (update.message.text === 'hi' ||
      update.message.text === 'Hi' ||
      update.message.text === 'hello' ||
      update.message.text === 'Hello') {
    bot.reply(update, 'well hi right back at you');
  } else if (update.message.text.indexOf('weather') > -1) {
    bot.sendTextMessageTo('It is currently sunny in Philadelphia', update.sender.id);
  } else {
    const messages = ['I\'m sorry about this.',
                      'But it seems like I couldn\'t understand your message.',
                      'Could you try reformulating it?']
    bot.sendTextCascadeTo(messages, update.sender.id)
  }
});
```

What's going on here is really fairly straightforward. The point of this code is really to expose to you the different ways there are to send messages in botmaster. In the first conditional block, I look to see if the text from the platform says something like "hello", if so, answer that way using the `reply` helper function. However, if the message contains the word "weather", we reply using the `sendTextMessageTo` helper function. In any other situation, we reply in a cascade of text messages using the `sendTextCascadeTo` helper function to send multiple text messages one after the other. If you want to see all the available send helper functions available to you in Botmaster, check it out [here](/working-with-botmaster/botmaster-basics/#outgoing-messages).

## Closing Comments

Now as mentioned at the beginning of this tutorial, this bot is not a very good or helpful bot. It's quite dumb and doesn't even leverage a lot of the Botmaster goodies like [middlewares](/working-with-botmaster/middleware), using [socket.io](/getting-started/socketio-setup) to have a bot on your own website. Or adding support for a different bot class as mentioned [here](/working-with-botmaster/writing-your-own-bot-class/). More importantly, it doesn't really understand anything being told to it and have a look at the list of tutorials we have to see how to leverage NLU tools such as Watson Conversation, Wit.ai, Api.ai and rasa-nlu with Botmaster.

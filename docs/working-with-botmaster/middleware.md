# Middleware

If you've gone through the [quickstart](/gettings-started/quickstart.md) guide, you've actually already used middleware (well incoming middleware in this case). We do so in the "Acting on updates" section.

Middleware in Botmaster is designed to work similarly to  what you would expect 
in an [express.js](http://expressjs.com/) app. I.e. almost all your code will reside in them.

Because Botmaster is a chatbot framework and not a web app framework, we go on and define two different types of middleware: `incoming` and `outgoing` middleware.

 * [Incoming middleware](#incoming-middleware) gets called in order of declaration whenever a valid update from one of the bots added to botmaster (using `botmaster.addBot()`) is received.

 * [Outgoing middleware](#outgoing-middleware) gets called in order of declaration whenever you send a message using one of the bot's sendMessage methods.

Both middleware types get added to their respective "middleware stack" by using botmaster's `use` method. Another helper method `useWrapped` can be used to add middleware. But we'll talk about that further down. A description of both methods can be found at the end of this document. For now, let's jump into examples:

## Incoming middleware

As mentioned briefly above, `incoming` middleware in Botmaster is similar to what you would have in express middleware and can be used similarly. They are all called in order of declaration upon receiving an update.

### Basic incoming middleware example

Here is a very simple example of how one would go on and use `incoming` middleware:

```js
// middleware that uses next (standard middleware you might be acquainted with)
botmaster.use({
  type: 'incoming',
  name: 'add-weather-to-update',
  controller: (bot, update, next) => {
    // assumed here that some weather API is queried to get that weatherInformation
    update.weather = {
      temperature: 23,
      unit: 'celcius',
    }
    next(); // next needs to be called if your controller does not return a promise
  }
});

// middleware that returns an explicit promise
botmaster.use({
  type: 'incoming',
  name: 'add-user-info-to-update',
  controller: (bot, update) => {
    // update.weather will exist here
    if (bot.retrievesUserInfo) {
      return bot.getUserInfo(update.sender.id).then((userInfo) => {
        update.userInfo = userInfo;
      })
    }

    return Promise.resolve();
  }
});

// middleware that uses async-await because we are using node7 with the async-await
// harmony flag or a transpiler like Babel.

botmaster.use({
  type: 'incoming',
  name: 'reply-to-user',
  controller: async (bot, update) => {
    let text;
    if (update.weather.temperature > 17) {
      text = 'the weather is warm';
    } else {
      text = 'the weather is cool';
    }

    if (update.userInfo) {
      text += ` ${update.userInfo.first_name}`;
    }

    const body = await bot.reply(update, text);
    // do stuff with the body object
  }
});
```

This is a very basic example. But hopefully, it gets the message through of how you can use `incoming` middleware. Here we see three ways to use middleware. All three are valid. I'll briefly address the three ways here:

1. Using `next` to go to the next middleware function declared in the stack. This is the most common way middleware functions have handed over control to the next middleware in the stack. Once your middleware function is entered, you do some things and then when you're ready, you call next(). It is handy to use middleware in this way whenever your middleware makes use of callback based apis or if it's synchronous in nature.

2. Returning a `Promise`. Another way to hand over control to the next middleware function in the stack in Botmaster is to return a Promise. Whenever the promise resolves, control will be handed down to the next middleware function in the stack. In our example, we return the promise from `getUserInfo` if the bot class can retrieve user info. Otherwise, we return a promise that resolves straight away.

3. Returning Promises is great. But it gets better when you start leveraging the use of async-await functions which are already supported in Node7+ (by using the `--harmony-async-await` flag). Or you can also use Babel or another transpiler to use them. Not how in this function we don't have to return anything at the end. This is because using async will wrap our function with a Promise that will resolve naturally when it runs its course. Also, using await anywhere within the function on any function that returns a promise will just pause until the promise resolves. That is what we do when we do: `const body = await bot.reply(update, text);`. The middleware won't go to the next one, because it is waiting for the reply function's promise to resolve. Using async-await with Botmaster middleware will soon be the preferred way to write middleware as it allows you to write synchronous looking code that just goes to the next middleware function whenever the function returns (or runs its course)

### Basic incoming middleware example with structure

In practice, your middleware code will really live within separate files that you would "require" within your main "app.js" file. That means that the previous example will have a tree structure similar to the following:

```
├── app.js
└── middleware
    ├── incoming
    │   ├── weather.js
    │   ├── user_info.js
    │   ├── reply.js
    │   └── index.js
    ├── outgoing // no outgoing middleware in this example
    |    └── index.js // this will remain an empty file for now
    └── wrapped // no wrapped middleware in this example
        └── index.js // this will remain an empty file for now
```

This is only a suggested structure (the one I use). Feel free to come up with a different, potentially better, structure that suits you better.

That means that the previous example's code will probably look more like this:

`middleware/incoming/weather.js`

```js
const addWeatherToUpdate = {
  type: 'incoming',
  name: 'add-weather-to-update',
  controller: (bot, update, next) => {
    // assumed here that some weather API is queried to get that weatherInformation
    update.weather = {
      temperature: 23,
      unit: 'celcius',
    }
    next(); // next needs to be called if your controller does not return a promise
  }
}

module.exports = {
  addWeatherToUpdate, // using shorthand here
}
```

`middleware/incoming/user_info.js`

```js
const addUserInfoToUpdate = {
  type: 'incoming',
  name: 'add-user-info-to-update',
  controller: (bot, update) => {
    // "update.weather" will exist here btw
    if (bot.retrievesUserInfo) {
      return bot.getUserInfo(update.sender.id).then((userInfo) => {
        update.userInfo = userInfo;
      })
    }

    return Promise.resolve();
  }
};

module.exports = {
  addUserInfoToUpdate,
}
```

`middleware/incoming/reply.js`

```js
const replyToUser = {
  type: 'incoming',
  name: 'reply-to-user',
  controller: async (bot, update) => {
    let text;
    if (update.weather.temperature > 17) {
      text = 'the weather is warm';
    } else {
      text = 'the weather is cool';
    }

    if (update.userInfo) {
      text += ` ${update.userInfo.first_name}`;
    }

    const body = await bot.reply(update, text);
    // do stuff with the body object
  }
});

module.exports = {
  replyToUser, // using shorthand here
}
```

`middleware/incoming/index.js`
```js
const weather = require('./weather');
const userInfo = require('./userInfo');
const reply = require('./reply');

module.exports = {
  weather,
  userInfo,
  reply,
};
```

`app.js`

```js
const incomingMiddleware = require('./middleware/incoming');

botmaster.use(incomingMiddleware.weather.addWeatherToUpdate);
botmaster.use(incomingMiddleware.userInfo.addUserInfoToUpdate);
botmaster.use(incomingMiddleware.reply.replyToUser);

botmaster.on('error', (bot, err) => {
  console.log(err.message);
})
```

This example is really the same as the first one.will be called only on bots of type `messenger` and the other one on all bots. We just separated it all in a reasonable file structure.

It should be clear by now that this reads much clearer than the previous example. Simply by reading the `app.js` file I can have an idea of what is going on in the code. Clearly, some weather information and user information is added to the `update` object. That information is then used to send customized reply to the user.

Do note also that we have added an error event listener on the `botmaster` object. This is done because there is no other way for us to catch errors occurring in incoming middleware. So we emit them like that so you can deal with them in this event listener.

Now that we've had a look at incoming middleware, let's have a look at how outgoing middleware works.

## Outgoing middleware

similar to the `incoming` middleware, the `outgoing` middleware is called in order of declaration. However, it is called on every message object sent by you the developer. To illustrate this, here's an example:

### Basic example

```js
botmaster.use({
  type: 'incoming',
  name: 'reply-to-user',
  controller: (bot, update) => {
    return bot.reply(update, 'Hello world');
  }
});

botmaster.use({
  type: 'outgoing',
  name: 'change-text',
  controller: (bot, update, message, next) => {
    console.log(message); // this is a full valid messenger object/ OutgoingMessage object
    message.message.text = "Hello you!";
    next();
  }
});
```

>The three types of middleware controller mentioned in incoming middleware are also valid with outgoing middleware. I.e. we could also have returned a Promise or does so using async-await functions.

In this example, the incoming middleware is what you would expect if you were simply trying to reply "Hello world" to any message. However, if you try this out, you'll see that you get a "Hello you!" text message back. Indeed, our middleware, aside from printing the message object to show you what it looks like, replaces the text with "Hello you".

This is really what you'll want to be doing within outgoing middleware. First use one of the Botmaster sendMessage helper functions to send a message, then edit it in your outgoing middleware functions. Botmaster simply creates the valid [messenger compatible] message object before hitting the outgoing middleware where you can play with this.

### Basic example with structure

As in the incoming middleware example, in practice, your middleware code will really live within separate files that you would "require: within your main "app.js" file. Using a structure similar to the one used in the incoming middleware example. We look at something like this:

```
├── app.js
└── middleware
    ├── incoming
    │   ├── reply.js
    │   └── index.js
    └── outgoing
        ├── message_transformers.js
        └── index.js
```

Where the code for incoming middleware looks something like this as you could expect:

`middleware/incoming/reply.js`

```js
const replyToUser = {
  type: 'incoming',
  name: 'reply-to-user',
  controller: (bot, update) => {
    return bot.reply(update, 'Hello world');
  }
});

module.exports = {
  replyToUser,
}
```

`middleware/incoming/index.js`
```js
const reply = require('./reply');

module.exports = {
  reply,
};
```

And the code for our outgoing middleware will look like this:

`middleware/outgoing/message_transformers.js`

```js
const changeText = {
  type: 'outgoing',
  name: 'change-text',
  controller: (bot, update, message, next) => {
    console.log(message); // this is a full valid messenger object/ OutgoingMessage object
    message.message.text = "Hello you!";
    next();
  }
}

module.exports = {
  changeText,
}
```

`middleware/outgoing/index.js`
```js
const messageTransformers = require('./message_transformers');

module.exports = {
  messageTransformers,
};
```

`app.js`

```js
const incomingMiddleware = require('./middleware/incoming');
const outgoingMiddleware = require('./middleware/outgoing');

botmaster.use(incomingMiddleware.reply.replyToUser);

botmaster.use(outgoingMiddleware.messageTransformers.changeText);
```

This might seem like slight overkill at this point because of how trivial of an example this is. But this adds clear structure to our project and when reading our app.js file we can already know what is going on. It also makes it very clear regarding what is going on if you were to add another middleware function right after the `changeText` one.

### Complete outgoing middleware example with structure

We first edit the reply we give to our user:

`middleware/incoming/reply.js`

```js
const replyToUser = {
  type: 'incoming',
  name: 'reply-to-user',
  controller: (bot, update) => {
    return bot.sendTextCascadeTo(['Hi there, I`m about to ask you to press buttons:',
      'Please press any of: ["Button1","Button2"]',
      'Thank you'], update.sender.id)
    .catch((err) => {
      console.log(err.message);
    })
  }
});

module.exports = {
  replyToUser,
}
```

Note, we are here using the Bot classes `sendTextCascadeTo` helper function to send text messages one after the other. See [Bot object](/working-with-botmaster/bot-object.md).

Also note that we have a catch bit there ready to catch any error that might occur within our outgoing middleware or if the platform we are sending the messages to responds with an error/4xx statusCode.

We now update our outgoing middleware code:

Taking this one step further, you can do something like the following to, say, send buttons without using the builtin `sendDefaultButtonMessageTo` method. We'll keep our structure and simply update the files to look like this:

`middleware/outgoing/message_transformers.js`
```js
const changeText = {
  type: 'outgoing',
  name: 'change-text',
  controller: (bot, update, message, next) => {
    if (message.message.text === 'Thank you') {
      // yes, this is very arbitrary. But again, tries to drive the point of how middleware works
      message.message.text = 'Thanks';
    }
    next();
  }
}

const addButtonsToMessage = {
  type: 'outgoing',
  name: 'add-buttons-to-message',
  controller: (bot, update, message) => {
    const text = message.message.text;

    // will match anything that looks like this: `'["Button1","Button2"]'`
    const buttonsRegexObject = text.match(/&\[.+]/); 
    if (buttonsRegexObject) {
      // extract buttonTitles into an array
      const buttonTitles = JSON.parse(buttonsRegexObject[0].substring(1));
      // remove them from the text
      const message.message.text = text.replace(buttonsRegexObject[0], '');
      // adds quick reply buttons to the OutgoingMessage object.
      message.addPayloadLessQuickReplies(buttonTitles);
    }

    return Promise.resolve(); // could have used next here too. But driving the point that promises work too
  }
}

module.exports = {
  changeText, // using shorthand here
  addButtonsToMessage,
}
```

This simple `addButtonsToMessage` middleware simply uses regular expressions to see if the text contains any bit of text that looks anything like the following: `'["Button1","Button2"]'`. If any such string is found, it then proceeds to remove said mentions from the text and then add a quick_replies component to your OutgoingMessage object. Note that it does so by using a helper method. These helper methods are available because Botmaster now wraps our message object in an outgoingMessage class that has helper functions to help with composing the message. See the [OutgoingMessage write-up](/working-with-botmaster/outgoing-message.md) for more on that.

We next have a look at `app.js` that also has to be transformed:

`app.js`

```js
const incomingMiddleware = require('./middleware/incoming');
const outgoingMiddleware = require('./middleware/outgoing');

botmaster.use(incomingMiddleware.reply.replyToUser);

botmaster.use(outgoingMiddleware.messageTransformers.changeText);
botmaster.use(outgoingMiddleware.messageTransformers.addButtonsToMessage);
```

Now this will work great. But actually, what i want to do is show the user a typing indicator right before sending every message that goes out. Because I'm using a sendCascade function, namely, `sendTextCascadeTo`, the best way to do so is to do this within an outgoing middleware function. Here's how we can edit `app.js` to achieve this goal:

`app.js`

```js
const incomingMiddleware = require('./middleware/incoming');
const outgoingMiddleware = require('./middleware/outgoing');

botmaster.use(incomingMiddleware.reply.replyToUser);

botmaster.use(outgoingMiddleware.messageTransformers.changeText);
botmaster.use(outgoingMiddleware.messageTransformers.addButtonsToMessage);

botmaster.use({
  type: 'outgoing',
  name: 'show-indicator-before-sending-message',
  controller: (bot, update, message, next) => {
    const userId = message.recipient.id;

    bot.sendIsTypingMessageTo(userId, { ignoreMiddleware: true })

    .then(() => {
      setTimeout(() => {
        next();
      }, 1000);
    };
  },
});

```

There's a few things going on in this added bit of code here. First we make it clear again that middleware code can technically live anywhere. It would be better to have it in a separate file somewhere. But this also works. Second, We introduce the `ignoreMiddleware` option when sending a message. This will always work and simply tells Botmaster to not go through any of the middleware with this message and send it directly. This is very important as otherwise, we would be stuck in an infinite loop trying to send an "is typing" indicator. Second we note that we use `setTimeout` to make it look like the bot is typing for about 1 second before firing out the message by calling `next()`. Note how we don't return the `bot.sendIsTypingMessageTo` promise here, if we did, the timeout wouldn't be respected and we would get an error, as `next` cannot be called when your middleware returns a promise.

## Using **skip** and **cancel**

Middleware comes with a few options to skip the middleware after a certain one or all together cancel sending a message (in outgoing middleware). `cancel` does the same as `skip` in incoming middleware.
Here's how you could use those.

```js
botmaster.use({
  type: 'incoming',
  name: 'first-middleware',
  controller: (bot, update) => {
    return useSomePromiseBasedFunction('something')
    .then((valueFromFunction) => {
      update.value = valueFromFunction;
      return 'skip'; // the returned promise will resolve with 'skip'
    })
  }
});

botmaster.use({
  type: 'incoming',
  name: 'second-middleware',
  controller: (bot, update, next) => {
    // this will never get hit and nothing really will happen as `first middleware` does not send any message
  }
});
```

`skip` can also be used by outgoing middleware along with `cancel`. Here is an example of using `cancel`:

```js
botmaster.use({
  type: 'incoming',
  name: 'incoming-middleware',
  controller: (bot, update) => {
    return bot.reply(update, 'Hey there');
  }
});

botmaster.use({
  type: 'outgoing',
  name: 'first-outgoing-middleware',
  controller: (bot, update, message) => {
    if (update.message.text === 'Hey there') { // for some arbitrary reason
      return Promise.resolve('cancel');
    }
  }
});

botmaster.use({
  type: 'outgoing',
  name: 'second-outgoing-middleware',
  controller: (bot, update, message) => {
    // this will not get hit
  }
});
```

In this last example, not only will "second outgoing middleware" not get hit, the message will also not get sent out.
Please note, valid syntax for our "first-outgoing-middleware are also the following two"

```js
botmaster.use({
  type: 'outgoing',
  name: 'first outgoing middleware',
  controller: async (bot, update, message) => { // if using transpiler or node 7.x with harmony flag
    if (update.message.text === 'Hey there') {
      return 'cancel';
    }
  }
});
```

and

```js
botmaster.use({
  type: 'outgoing',
  name: 'first outgoing middleware',
  controller: (bot, update, message, next) => {
    if (update.message.text === 'Hey there') {
      next('cancel');
    }
  }
});
```

Now that we've covered almost all of middleware let's quickly introduce how all this middleware was added. We made extensive use of `botmaster.use` throughout this document and this is 

#### Here is the signature of `botmaster.use`

| Parameter | Description
|--- |---
| middlewareObject  | a valid middleware object.

Now this might not be very helpful as what we really want to know is what this object looks like. It looks like this:

| Parameter | Description
|--- |---
| type | either `'incoming'` or `'outgoing'` depending on what middleware you are setting up.
| name |(__optional__) The name for this middleware. This is helpful in debugging, and you can expect it to be used in future versions of Botmaster. But it is optional. I strongly recommend naming your middleware.
| controller | The actual middleware function that will be called. It is of type: `function(bot, update, next)` on `incoming` and `function(bot, update, message, next)` on `outgoing`. The `next` parameter can be omitted if your controller returns a promise. Examples below ensue.
| includeEcho | (__optional__) Only valid for __incoming__ middleware. Whether or not to run this middleware on echo updates. __Defaults to false__.
| includeDelivery | (__optional__) Only valid for __incoming__ middleware. Whether or not to run this middleware on delivery updates. __Defaults to false__.
| includeRead | (__optional__) Only valid for __incoming__ middleware. Whether or not to run this middleware user "user read" updates. __Defaults to false__.

#### `botmaster.useWrapped`

There is another way to declare middleware in botmaster as of v3. It is by using the useWrapped method. This method should be used after all your normal middleware has been setup using `botmaster.use`. Essentially, what it does is setup an incoming middleware at the very beginning of your incoming middleware stack and another one at the very end of your outgoing middleware stack.

Its signature looks like this:

| Parameter | Description
|--- |---
| incomingMiddlewareObject  | a valid incoming middleware object. (as described above)
| outgoingMiddlewareObject  | a valid outgoing middleware object. (as described above)

And it would be used as such:

```js
botmaster.useWrapped(incomingMiddleware, outgoingMiddleware);
```

Where `incomingMiddleware` and `outgoingMiddleware` are valid middlewares of their respective types.
This is useful if writing a middleware package that want to be first to get the update object and last to see it when it goes out.
It is used in [botmaster-session-ware](https://github.com/botmasterai/botmaster-session-ware) for example.

#### Where is my middleware

Although I doubt most would want to use this, it's good to know that middleware is accessible via all botmaster instances. Middleware stacks are exposed via `botmaster.middleware.incomingMiddlewareStack` and
`botmaster.middleware.outgoingMiddlewareStack`. Unless you really know what you are doing, it is best to leave those alone.

## External middleware

This is all great. But Using the code in `addButtonsToMessage` to add buttons to your message is probably not the best. Indeed, external middleware packages provide better solutions to this problem. To solve this particular problem, I would suggest having a look at [fulfill](/middleware/fulfill.md). Like in any other framework that contains middleware, middleware can be put into packages. These packages are then available and downloadable via `yarn` or `npm` and thus easily accessible in your code. 

Have a look at the [middlewares](/middlewares/index.md) to see what official middleware is out there.
>This documentation is valid for botmaster 2.x.x This guide will be update once a version of botmaster-fulfill for botmaster 3.x.x is published

# Fulfill Middleware

>In addition, to this documentation, we highly recommend that you read the [fulfill tutorial](/tutorials/using-fulfill/).

**botmaster-fulfill** provides a text-friendly way to integrate actions with your bot. You supply an object of action-functions that can return synchronously or asynchronously and replace text in the response, generate new responses, or do what the response claims to do, by for example actually placing the users burger order for him using a REST API.



<!-- TOC depthFrom:1 depthTo:2 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Markup for your chatbot.](#markup-for-your-chatbot)
- [Quick start](#quick-start)
- [Standard Actions](#standard-actions)
	- [pause](#pause)
	- [greet](#greet)
- [In-depth](#in-depth)
- [How to use the Fulfill API](#how-to-use-the-fulfill-api)
	- [Format for the action spec](#format-for-the-action-spec)
	- [More info on params:](#more-info-on-params)
	- [Additional controller configuration options](#additional-controller-configuration-options)
- [Using botmaster-fulfill](#using-botmaster-fulfill)
	- [Additional middleware options](#additional-middleware-options)
- [Using standalone without botmaster](#using-standalone-without-botmaster)
- [Setup hint - drag and drop action modules](#setup-hint-drag-and-drop-action-modules)
- [Debug](#debug)

<!-- /TOC -->



# Markup for your chatbot.

```html
 Chabot: "Let me see if I can place your order, <pause /> <placeOrder id=12 />"
 ```

You just built a chatbot. Its funny, and it says useful stuff. But how do you get it to do something?

```html
Shaquille O'Neal: Little man, I ordered tomatoes on this Good Burger, and I don't see no tomatoes!

Ed: Well, hang on... <modifyOrder style='slap'>Tomatoes</modifyOrder>
```
_Good Burger, Brian Robbins (1997)_

Fulfill makes this easy with declarative markup that is easy to understand for non-technical chat authors and is easy to integrate into your current botmaster stack.

Available on npm:
https://www.npmjs.com/package/botmaster-fulfill

# Quick start
All you need to get started.

```bash
npm install botmaster-fulfill --save
npm install botmaster-fulfill-actions --save
```

```js
const {FulfillWare} = require('botmaster-fulfill');
const actions = require('botmaster-fulfill-actions');
const Botmaster = require('botmaster');
const botsSettings = require('./my-bots-settings');
const botmaster = new Botmaster({botsSettings});
actions.hi = {
    controller: () => 'hi there!'
};
botmaster.use('outgoing', FulfillWare({actions}));
botmaster.on('update', bot => bot.sendMessage('<hi /><pause wait=2500 />What is your name?'));
```

This will send two messages "hi there!" and "What is your name?" with a delay of 2.5 seconds between them.

# Standard Actions

The package "botmaster-fulfill-actions" provides out-of-the-box standard actions.

## pause

Break text up with a separate messages pausing before each one

```xml
<pause wait=2000 />
```

 evaluated in series
 after evaluating all text / xml before removed
 controller sends text before and then waits before allowing rest of text/xml to be evaluated
 if the bot implements typing a typing status is sent between pauses.

**Parameters**

-   `wait`  {String} how long to wait in ms between each defaults to 1000

## greet

Greet users with a greeting that reflects the time of day

```xml
<greet />
<greet tz='America/New_York' lang='es' />
```

Outputs based on the detected system language

**English (en)**

-   between 4 am and 12 pm say "Good morning"
-   between 12 pm and 5pm  say "Good afternoon"
-   between 5 pm and 4am  say "Good evening"

**Spanish (es)**

-   between 4 am and 12 pm say "Buenos dias"
-   between 12 pm and 8pm  say "Buenas tardes"
-   between 8 pm and 4am  say "Buenas noches"

**Parameters**

-   `tz` **[String](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String)** Which timezone to use for the time-based greeting. Defaults to GMT. To see available options see <http://momentjs.com/timezone/>
-   `lang` **[String](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String)** Which language to use. Defaults to system locale setting


# In-depth
botmaster-fulfill extends botmaster with a repertoire of actions that your bots can perform with a declarative and easy to use syntax based on XML. It is a great way to separate business logic (when to do what and where) and functional logic (how to do it).

When writing the output of your bots all you have to do is write:

```html
"ok <userName />, im placing your order for you. <placeOrder /> here you go. "
```

Here **userName** could for example mean get a human readable version of the audience's name.

**placeOrder**  does two much more interesting things and demonstrates the power of using markup over a simple field-based JSON payload. First, it sends the rest of the message before the tag ("ok bob, I'm placing your order for you.") onwards so that the user knows we are placing his order. Second, it starts placing the order and when its done, it sends the text following it, "here you go."

And in order to connect that all you have to do is write in plain js:

```js
const actions = {
    // for <userName />
    userName: {
        controller: function(params) {
            // return a promise (using an imaginary getUser method)
            return getUser(params.context.user)
                .then( function(result) {
                    return result.user.name
                    // if name is "bob" then the text would be
                    // "ok bob, I'm placing your oder for you."
                });
        }
    },
    // for <placeOrder />
    placeOrder: {
        // replace not just the tag, but the text after too
        replace: 'after',
        controller: function(params) {
            placeOrder(params.context.order)
                .then( function(result) {
                    // once the order is placed then send the rest of the message
                    params.sendMessage(params.after)
                });
            // remove the tag and the text after it and send the message ("ok bob, I'm placing your order for you.")
            return '';
        }
    }
}
```

The most ipmortant part of the action spec is what the controller function returns. The return value If you want to strip it out

# How to use the Fulfill API

You use fulfill by specifying an action spec. At a minimum your spec must specify controller as a javascript function that can return either by callback, promise or even synchronously. The action controller receives a params object which it can use as parameters such as the contents of the tag or data about the chat, which is stored in a variable called context. It can update the context and its return value will replace the tag. If the returned value from an action includes another action, this action will also be evaluated.

Once fulfill has finished evaluating or actions you get back an updated response string and any context passed in has been modified in place.

## Format for the action spec

You should provide an **actions** object where the key is the name of the xml element that will be matched. The value should specify another object that has the key **controller** which as a value should have a function that takes **params** and an optional callback.

```javascript
const actions = {
// sync <burgerImage /> example
  burgerImage: {
    controller: function() {
      return "<img url='some/complex/static/path/burger.png'>";
    }
  },
// error first callback <modifyOrder style='someStyle'>Stuff to order</modifyOrder>
  modifyOrder: {
    controller: function(params, cb) {
      myOrderAPI.modify(params.context.orderId, params.content, params.attributes.style, function(err) {
        if (! err) {
          cb(null, "There, consider yourself tomatoed!");
        } else {
          cb(null, "Sorry I can't modify your order now. Please check again later")
        }
        });
    }
  },
// promise example
  hi: {
    controller: function(params) {
        return new Promise(function(resolve, reject) {
          resolve("hello world");
        });
    }
  }
};
```

## More info on params:

Params argument provides several variables that can control its behavior.

- **params.context**: a reference to the context object which can be updated or read
- **params.content**: the literal text between the xml element opening and closing
- **params.attributes**: an object where keys are the name of an attribute against the xml element and the the value is the value of that attribute.
- **params.after**: all text and tags before the tag.
- **params.before**: all text and tags preceding the tag.

### Context:

**context** provides a great deal of control and allows you to pass custom dependencies down to your controllers.
It should not be confused with the **context** variable that your NLU like IBM Conversations uses.

For example:
```js
const context = {
    myEnvironment: {
        username, password
    }
    myApis: {
        dbLibrary
    }
}

botmaster.use('outgoing', outgoing({actions, context}))
```

Fulfill will merge these custom context with several standard context objects available when using as part of botmaster.

#### Standard Context

|Key|Description
|---|---
|params.update|Botmaster update object
|params.bot|Botmaster bot object

>To get an NLU's context the update handler or one of the middleware's should have set it in **update**. So for example your context might be in **context.update.context**.

### Getting impatient - emitting updates before fulfill has completed

You might want to cascade messages and separate them by one minute pauses. Or you want to let your user know that you are working on it. Whatever your use case, emitting multiple updates is not a problem. In botmaster you will also have available **context.bot.sendMessage** which you can use to send another template response down the pipeline. This will be processed again by fulfill since fulfill is part of the outgoing middleware stack. This is actually advantageous because this way you can be sure that there are no further actions to fulfill from the emitted message.

If you are not using botmaster you can achieve the same thing by including in the context an emitter which should set off a handler that calls fulfill.


## Additional controller configuration options

By default, an action modifies the response text by replacing the xml tag with its response inline. This allows multiple actions in a response to not conflict. Note that this default does not allow you to modify any text surrounding the tag.

Take the following example:
```xml
<optional /> hi how are <you /> today?
```
With the default mode you can only replace the tag. There are however other modes available that allow you to modify surrounding text.

**action.replace**:

1. **= 'before'** Replace the tag and text before the tag until another tag is reached. In the example above setting **you** to this mode will have the controller control up to **hi how are <you />**.
2. **= after** Replace the tag and text after the tag until another tag is reached. In the example above setting **after** to this mode will set the controller to control **<optional /> hi how are you**.
3. **= adjacent** Replace the tag and text before and after the tag until other tags are reached. In the example above setting **you** to this mode will set the controller to control **hi how are <you /> today ?**.


# Using botmaster-fulfill

Botmaster-fulfill exports two functions. The first is **fulfill** and implements the fulfill API. The second **FulfillWare** produces botmaster outgoing middleware.

If you look at the quick start example the necessary steps are:

1. require the necessary dependencies (the examples gets the outgoing function through destructuring)
2. connect our bots to botmaster
3. get actions pass as settings object to **outgoing** function for it to generate our middleware.
4. register the resulting middleware to botmaster outgoing middlware.

## Additional middleware options

All of these settings are optional and have reasonable defaults.

1. **settings.context** By default **{bot, update}** is passed as the context object which is made available to actions. If you want any other variables available in the context assign them as values in the **settings.object**. **bot** and **update** will still be passed into the fulfill context and will overwrite any **bot** or **update** in your custom context.
2. **settings.updateToInput** By default **update.message.text** is used as the input into response. If this is not acceptable you can define your own function. It will receive an object **{bot, update}** and expect a string response.
3. **settings.responseToUpdate** By default **update.message.text** is replaced with the response from fulfill. It also returns true for sending an update when the response is not empty (**''**). To define your own setter define a function that accepts **update** and **response**, modifies the update in place, and returns true or false whether that update should be sent.

# Using standalone without botmaster

```js
const {fulfill} = require('botmaster-fulfill');
// the input and context would be from your chatbot, but assume they look like this.
// also assume actions above
var input = "<hi />";
var context = {};
fulfill(actions, context, input, function(err, response)  {
    // response =  'hello world!'
})
```

# Setup hint - drag and drop action modules

You can drag and drop actions by requiring from an actions folder where you setup your middleware:
```js
const actions = require('./actions');
```

In your your actions directory then need to include an index.js:
```js
const fs = require("fs");
const path = require("path");

fs.readdirSync(__dirname).forEach(function (file) {
    if (file.endsWith(".js") && file !== "index.js")
        exports[file.substr(0, file.length - 3)] = require("./" + file);
});
```

Each action module should export an object that specifies a controller.

# Debug

You can enable debug mode by setting `DEBUG = botmaster:fulfill:*` in your environment.

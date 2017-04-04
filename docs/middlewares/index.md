# Middleware

Middleware extends botmaster with additional functionality. Because of their modular nature they are great for extending your bots with functionality very quickly. Read more about how they work [here](/working-with-botmaster/middleware)

## Official middleware

### Incoming

1. [Watson Conversation Ware](https://github.com/botmasterai/botmaster-watson-conversation-ware) - Create a bot that communicates with Watson Conversation. Whenever an incoming text update comes
in, it will be forwarded to your specified Watson Conversation service and the 
Watson response will be added to the update object. It will add the following to
your update: `update.watsonUpdate`, `update.watsonConversation` and `update.session.watsonContext`. As you can guess from that last part, in order
to use Watson Conversation Ware, you'll need to be using Session Ware too. Install with. Install it with: `yarn add botmaster-watson-conversation-ware` or `npm i --save botmaster-watson-conversation-ware`.

### Outgoing

1. [Fulfill](/middlewares/fulfill.md) - Declarative markup API and engine to integrate internal or external APIs with botmaster. install it with `yarn add botmaster-fullfill` or `npm i botmaster-fulfill -S`.

### Wrapped

1. [Session Ware](https://github.com/botmasterai/botmaster-session-ware) - Add a
persistent session to your bot. If used, `update.session` will exist. Install it
with `yarn add botmaster-session-ware` or `npm i --save botmaster-session-ware`
# Working with Botmaster

The following sections are meant to be read in order after having gone through the [quickstart](/getting-sarted/quickstart.md). Every section starts with the basic concepts on the topic and end with more advanced ones.

1. [Bot object](bot-object.md) - The bot objects that have to be added to botmaster and that you will be interacting with within all your middleware.

2. [Middleware](middleware.md) - As most of the code you'll be writing will
actually be in those, it makes sense to spend some time getting acquainted with botmaster middleware.

3. [Incoming Update](incoming-update.md) - As mentioned in this documentation's [introduction](/#botmaster-is-platform-agnostic), standardization is at the heart of the Botmaster philosophy. See what this means for the update objects you get from the various platforms you might want to add support for.

4. [Outgoing Update](incoming-update.md) - Similarly, see what this means for the message objects you send to the various platforms.

5. [Botmaster object](botmaster-object.md) - Need more control over the server that botmaster receives updates on? read this section

6. [Writing your own bot class](writing-your-own-bot-class.md) - Read this section if you want to start adding support for a different bot platform (which may be your own).

# Debug

You can enable debug mode by setting `DEBUG = botmaster:*` in your environment.
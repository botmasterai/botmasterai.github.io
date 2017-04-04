# Twitter setup

## Getting your Credentials

Twitter's setup is slightly more tricky than one would wish. Because Twitter requires you to create an actual account and not a page or a bot, you'll have to do a few more steps.

#### Setting up the bot account

* Just create a standard twitter account as you would any other. Name it as you want.
* navigate to your security and privacy settings (click on your image profile > settings > privacy and security settings)
* scroll to the bottom of the page and make sure "Receive Direct Messages from anyone" is ticked. (currently this has to be done because of Twitter's rules concerning DMs, where in order to send a DM to someone, they have to be following you).

#### Setting up the app

*  Navigate to the somewhat hard to find Twitter developer app dashboard at: https://apps.twitter.com/
* Click Create New App. Enter your details (callback URL is not required if you are starting from scratch here). 'Website' can take in a placeholder like (http://www.example.com)
* Now navigate straight to the 'Permissions' tab(do this before going to the 'Keys and Access Tokens' tab). Select 'Read, Write and Access direct messages' and then click 'Update Setting'
* Navigate to the 'Keys and Access Tokens' tab. You'll find your consumerKey and consumerSecret right here
* Scroll down and click on 'Create my access token'. You now have your accessToken  and your accessTokenSecret

! Makes sure not to create your access token before having reset your permissions. If you do that, you will need to change your permissions then regenerate your access token.

That should about do it. Because twitter DM is not completely separate from the rest of Twitter, it behaves quite differently from the other platforms on many aspects. These points are covered in [working with botmaster](/working-with-botmaster).

## Code

```js
const Botmaster = require('botmaster');
const botmaster = new Botmaster();

const twitterSettings = {
  credentials: {
    consumerKey: 'YOUR consumerKey',
    consumerSecret: 'YOUR consumerSecret',
    accessToken: 'YOUR accessToken',
    accessTokenSecret: 'YOUR accessTokenSecret',
  }
}

const twitterBot = new Botmaster.botTypes.TwitterBot(twitterSettings);
botmaster.addBot(twitterBot);

botmaster.on('update', (bot, update) => {
  bot.reply(update, 'Right back at you');
});
```

#### Note on attachment types and conversions
Attachment type conversion on incoming updates works as such for __Twitter__:

| Twitter Type | Botmaster conversion
|--- |---
| photo | image
| video  | video
| gif  | video

!!!Yes `gif` becomes a `video`. because Twitter doesn't actually use gifs the way you would expect it to. It simply loops over a short `.mp4` video.

Also, here's an important caveat for Twitter bot developers who are receiving attachments. Image links that come in from the Twitter API will be private and not public, which makes using them quite tricky. You might need to make authenticated requests to do so. The twitterBot objects you will receive in the update will have a `bot.twit` object. Documentation for how to use this is available [here](https://github.com/ttezel/twit).

Receiving and sending attachments [the Botmaster way] is not yet supported on **Slack** as of version 2.2.3. However, Slack supports url unfurling (meaning if you send images and other types of media urls in your message, this will be shown in the messages and users won't just see a url). Also, because of how Botmaster is built (i.e. keep all information from the original message) you can find all the necessary information in the `update.raw` object of the update.

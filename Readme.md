go to http://botmasterai.com to read the documentation.

## to contribute to this documentation

#### 1. Copy project locally
``` bash
git clone git@github.com:botmasterai/botmasterai.github.io.git
cd botmasterai.github.io
```

#### 2. Install dependencies
``` bash
yarn // or npm install
```

#### 3. Do some changes in the markdown in `./docs`

#### 4. See how those changes would look in production
```
yarn watch // or npm run watch
```

If you now go to http://localhost:4000 you will see your version of the docs running. Whenever you update the ./docs folder, your documentation will be updated. When happy with the changes, CTRL-C out of it and then:

#### 5. Make sure you build the whole project
```
yarn build // or npm run build
```

This will make sure the botmaster favicon is being used as well as build the whole project for you if you skipped step 4.

#### 6. Submit your Pull Request

As the title says, you can then push to your fork and submit the Pull Request.
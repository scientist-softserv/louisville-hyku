### Installing the application in a developent environment at Notch8

1. First clone the repository and cd into the folder

2. Install Stack Car
```bash
gem install stack_car
```

3. If this is the first time building the application or if any of the dependancies changed, please build with:
```bash
sc build
```

4. After building the application please install and start dory with:
```bash
gem install dory
dory up
```
Note: Be sure to [adjust your ~/.dory.yml file to support the .test tld](https://github.com/FreedomBen/dory#config-file).

5. Bring the container up with:
```bash
sc up
```

6. Once the application is up and running, navigate to [single.test](https://single.test)in the browser and log in with the following credentials:

login un: `admin@example.com`
pw: `testing123`
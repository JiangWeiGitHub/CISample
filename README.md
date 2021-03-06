# 持续集成相关操作步骤整理:

## 目的
通过持续集成的方式, 当`github`上的源码项目发生`push tag`动作时, 自动编译生成可执行程序和安装包, 并传回`github releases`供用户使用

## 介绍:
操作步骤分为两个平台: windows(使用`appveyor`)和mac(使用`travis`), 因为一次代码和tag提交会生成一份指定编号的release,而两个平台使用不同的ci服务,当有新tag时,会造成两个ci服务都往`github releases`推送相同release编号的生成包,造成第二次推送失败, 所以建议两个平台项目分开

## Sample
+ [**Windows**](https://github.com/JiangWeiGitHub/fruitmix-desktop-win)
+ [**Mac**](https://github.com/JiangWeiGitHub/fruitmix-desktop-mac)

## 流程
### windows平台:
+ [*appveyor*](https://ci.appveyor.com/projects)注册帐号
+ 将github项目加入appveyor
+ 从`https://github.com/settings/tokens`获取token
+ 使用appveyor官网工具([*Link*](https://ci.appveyor.com/tools/encrypt))加密上一步的token
+ 在项目根目录下编写配置文件`appveyor.yml`,将`auth_token`键名后添加上一步的加密后字符串

```
environment:
  nodejs_version: "6"
  skip_tags: false

install:
  - npm install
  - ./node_modules/.bin/webpack -p
  - npm run build

build: off

build_script:
  - ./node_modules/.bin/build --config ./electron-builder.yml --win

test: off

artifacts:
  - path: ./dist/testApp*
    name: testApp

deploy:
  - provider: GitHub
    artifact: testApp
    draft: false
    prerelease: false
    
    auth_token:
      secure: 'vj997csmzYo+h1Vf9o87CjWj18njqemEDUfhGMqLjPpGYlsgD1IXlmhVGGJbzG31'
      
    on:
      appveyor_repo_tag: true
```

  注意：键`artifacts`->`name`的值和`deploy`->`atrifact`的值必须一致
+ 在shell环境下执行git相关命令，创建新的`tag`标签
```
git add ...
git commit ...
git tag -a v?.?.?
git push origin master --tag
```
+ appveyor页面随即提示有新的build,等待操作完成后,访问`github releases`页面即可发现最新生成包

+ appveyor向github推送build完成的文件包时, 需要在appveyor的页面上加入环境变量`appveyor_repo_tag`和`GH_TOKEN`, 现阶段发现`appveyor.yml`中配置`appveyor_repo_tag`变量无效, 只有加在网页页面配置项中才起作用

+ **注意**: 如果使用electron-builder工具的auto-update功能, 则建议不要使用appveyor的deploy功能, 而是使用electron-builder的cli工具中的-p (--publish)功能向github推送新生成的文件包 (即`./node_modules/.bin/build --config ./electron-builder.yml -p always --win`), 否则现阶段发现使用appveyor推送到github上的文件包缺少`latest.yml`文件, just like

```
  environment:
    nodejs_version: "6"
    skip_tags: false

  install:
    - npm install
    - npm uninstall babel
    - npm install babel-cli
    - npm install electron-builder --save-dev
    - npm install electron-log electron-updater --save
    - ./node_modules/.bin/webpack -p
    - npm run build

  build: off

  build_script:
    - ./node_modules/.bin/build --config ./electron-builder.yml --win -p always

  test: off
```

### macos平台:
+ [*travis*](https://travis-ci.org/)注册帐号
+ 将github项目加入travis
+ 在项目根目录编写`.travis.yml`配置文件

  备注: 此时的配置文件只是包含部分内容, 需要后续步骤补充修改
  
  **重要**: 配置文件中的`osx_image`字段现阶段指定为`xcode8`, 不要使用更高版本，否则travis在build时, `code signing`环节会报错
```
### 配置文件内容 ###
sudo: true
language: node_js
node_js: '6'
os: osx
osx_image: xcode8

branches:
  except:
  - master

before_install:
  - if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then brew update; fi

install:
  - npm install
  - "./node_modules/.bin/webpack -p"
  - npm run build

script:
  - "./node_modules/.bin/build --config ./electron-builder.yml --mac"
```
+ 从`https://github.com/settings/tokens`获取token
+ 安装travis官网工具
```
### 安装工具 ###
sudo apt-get install python-software-properties
sudo apt-add-repository ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install ruby2.1 ruby2.1-dev ruby-switch
sudo ruby-switch --set ruby2.1
sudo gem install travis -v 1.8.8 --no-rdoc --no-ri
```
+ 使用travis工具
  `travis setup releases`
  
  备注: 该命令包含用户交互界面, 根据项目具体信息填写相关问题, 有一步需要将前面的token填入进去

+ 上步骤完成后, `.travis.yml`配置文件被工具自动修改, 增添了`deploy`字段, 在此基础上继续完善该文件
```
sudo: true
language: node_js
node_js: '6'
os: osx
osx_image: xcode8

branches:
  except:
  - master

before_install:
  - if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then brew update; fi

install:
  - npm install
  - "./node_modules/.bin/webpack -p"
  - npm run build

script:
  - "./node_modules/.bin/build --config ./electron-builder.yml --mac"

deploy:
  provider: releases
  prerelease: false
  api_key:
    secure: dDAbiCuWnsTQRhjMQAPxg2gvcRJ2FD9OUuU4Yyg7SRBMFYv/Wld9W/E1hPdmvgWgJpSJ5Z/KBksSxTZslQejsnmC9cPJ8yiDuBgcLjWp8TXtvS7kAYhPZub3CErORUVhkyn3U6Zk9l9jEqxkNkXwQckIpzX5OGV/69BlD24So0g3nHY22MnGkegXkfO4EWvSmdqouFvEujjG/EuglFqAnu8YgW5p3f5r8YTJavCQE7UpyaTE4cekmi2pbpZ1absjD0FTItfUbliXdR5eR9FQcx3vmtyGpIosye0JjJUxgeAq8At7DYoXg+9o08Nk69mSDZVPlYqNC8AOIGQgTqoutJoo04HA96xJITm/WcSlPGrHkov5L3Xzw4zjuHeJSQpxEAin9ovY647mmO03VgLDLC0c/XAhW2t7Hp0NmZ8NP6Yg7mnlv68/iF+Y/ZYfOJJyesocYCPoEWmJZH9nwDSCOcTBRjLC6E1SGGojhETAjJvZX8D5LhTrCPzG+XV55AbaurDYg4r72CvW7Fij40XgVCSm6yMUMAP38k4ukwrdXnnScNZgXESFDQUsOBDOqbIcGrW4vMIlTKmDCQ7Td5nXLjbDkZaP0ckEQ/cYuAXBBvLlv5y3/11tlcHqRqORV3IkLQLxAckO9kZqEF4h2SPrS7EmuxoFfVc2ZyUBmMsfnkc=
  file: dist/testApp-1.0.0.dmg
  skip_cleanup: true
  on:
    repo: JiangWeiGitHub/wisnucAssistant-mac
    tags: true
```
+ 为了`code signing`, 先在MAC主机上导出证书，具体操作参看下列示例
```
1. Open Keychain.

2. Select login keychain, and My Certificates category.

3. Select all required certificates (hint: use cmd-click to select several):

    3.1 Developer ID Application: to sign app for macOS.
 
    3.2 3rd Party Mac Developer Application: and 3rd Party Mac Developer Installer: to sign app for MAS (Mac App Store).
 
    3.3 Developer ID Application: and Developer ID Installer to sign app and installer for distribution outside of the Mac App Store.
 
    Please note – you can select as many certificates, as need. No restrictions on electron-builder side. All selected certificates will be imported into temporary keychain on CI server.

4. Open context menu and Export.
```
  备注: 记住导出时使用的密码
+ 将生成的`p12`加入github源码池中, 并记录好该文件的`https`地址, 如[*Sample File*](https://github.com/JiangWeiGitHub/wisnucAssistant-mac/raw/master/certificate.p12)
+ 在travis的项目页面上点击`More options`->`Settings`, 在`Environment Variables`下增加两个字段`CSC_LINK`, `CSC_KEY_PASSWORD`, `CSC_LINK`字段的值即为上一步的`p12`文件的https地址, `CSC_KEY_PASSWORD`即为导出`p12`文件时输入的密码
+ 在shell环境下执行git相关命令，创建新的tag标签
```
git add ...
git commit ...
git tag -a v?.?.?
git push origin master --tag
```
+ travis页面随即提示有新的build, 等待操作完成后, 访问`github releases`页面即可发现最新生成包

+ **注意**: 如果使用electron-builder工具的auto-update功能, 则建议不要使用travis的deploy功能, 而是使用electron-builder的cli工具中的-p (--publish)功能向github推送新生成的文件包 (即`./node_modules/.bin/build --config ./electron-builder.yml -p always --mac`), 否则现阶段发现使用travis推送到github上的文件包缺少`latest-mac.json`文件, just like

```
  sudo: true
  language: node_js
  node_js: '6'
  os: osx
  osx_image: xcode8

  branches:
    except:
    - master

  before_install:
    - if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then brew update; fi

  install:
    - npm install
    - npm uninstall babel
    - npm install babel-cli
    - npm install electron-builder --save-dev
    - npm install electron-log electron-updater --save
    - ./node_modules/.bin/webpack -p
    - npm run build

  script:
    - "./node_modules/.bin/build --config ./electron-builder.yml --mac -p always"

  #deploy:
  #  provider: releases
  #  prerelease: false
  #  api_key:
  #    secure: dDAbiCuWnsTQRhjMQAPxg2gvcRJ2FD9OUuU4Yyg7SRBMFYv/Wld9W/E1hPdmvgWgJpSJ5Z/KBksSxTZslQejsnmC9cPJ8yiDuBgcLjWp8TXtvS7kAYhPZub3CErORUVhkyn3U6Zk9l9jEqxkNkXwQckIpzX5OGV/69BlD24So0g3nHY22MnGkegXkfO4EWvSmdqouFvEujjG/EuglFqAnu8YgW5p3f5r8YTJavCQE7UpyaTE4cekmi2pbpZ1absjD0FTItfUbliXdR5eR9FQcx3vmtyGpIosye0JjJUxgeAq8At7DYoXg+9o08Nk69mSDZVPlYqNC8AOIGQgTqoutJoo04HA96xJITm/WcSlPGrHkov5L3Xzw4zjuHeJSQpxEAin9ovY647mmO03VgLDLC0c/XAhW2t7Hp0NmZ8NP6Yg7mnlv68/iF+Y/ZYfOJJyesocYCPoEWmJZH9nwDSCOcTBRjLC6E1SGGojhETAjJvZX8D5LhTrCPzG+XV55AbaurDYg4r72CvW7Fij40XgVCSm6yMUMAP38k4ukwrdXnnScNZgXESFDQUsOBDOqbIcGrW4vMIlTKmDCQ7Td5nXLjbDkZaP0ckEQ/cYuAXBBvLlv5y3/11tlcHqRqORV3IkLQLxAckO9kZqEF4h2SPrS7EmuxoFfVc2ZyUBmMsfnkc=
  #  file_glob: true
  #  file: dist/*
  #  skip_cleanup: true
  #  on:
  #    repo: JiangWeiGitHub/fruitmix-desktop-mac
  #    tags: true
```

+ electron-builder向github推送build完成的文件包时, 需要在travis的页面上加入环境变量`GH_TOKEN`

+ **警告**: 使用electron-builder.yml时, 一定要加上zip字段, 否则`latest-mac.json`不会生成, 配置如下:

```
    appId: com.wisnuc.app
    copyright: wisnuc
    productName: testApp

    asar: false

    directories:
      buildResources: /
      output: dist/

    files:
      - "**/*"

    dmg:
      contents:
        - type: link
          path: /Applications
          x: 410
          y: 150
        - type: file
          x: 130
          y: 150

    mac:
      target:
        - dmg
        - zip
      category: public.app-category.tools

    win:
      target: nsis

    linux:
      target:
        - deb
        - AppImage
```

### electron-updater使用
[Wiki Site](https://github.com/electron-userland/electron-builder/wiki/Auto-Update)

源码如下:

```
  ...
  ...
  
  import { autoUpdater } from 'electron-updater'
  import log from 'electron-log'

  ...
  ...

  app.on('ready', function() {

    ...
    ...
  
    autoUpdater.checkForUpdates()

    ...
    ...
  }

  ...
  ...
  

  autoUpdater.logger = log;
  autoUpdater.logger.transports.file.level = 'info';
  log.info('App starting...');

  var sendStatusToWindow = text => {
    log.info(text)
    getMainWindow().webContents.send('message', text)
  }

  autoUpdater.on('checking-for-update', () => {
    sendStatusToWindow('Checking for update...')
  })

  autoUpdater.on('update-available', (ev, info) => {
    sendStatusToWindow('Update available.')
  })

  autoUpdater.on('update-not-available', (ev, info) => {
    sendStatusToWindow('Update not available.')
  })

  autoUpdater.on('error', (ev, err) => {
    sendStatusToWindow(err)
    sendStatusToWindow('Error in auto-updater.')
  })

  autoUpdater.on('download-progress', (ev, progressObj) => {
    sendStatusToWindow('Download progress...')
  })

  autoUpdater.on('update-downloaded', (ev, info) => {
    sendStatusToWindow('Update downloaded; will install in 5 seconds')
  })

  ...
  ...  
```

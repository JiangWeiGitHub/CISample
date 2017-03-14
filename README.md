# 持续集成操作步骤:

## 目的
将github上的源码项目通过持续集成的方式自动编译生成可执行程序和安装包,并传回github release供用户使用

## 介绍:
操作步骤分为两个平台: windows和mac, 因为一次代码和tag提交会生成一份指定编号的release,而两个平台使用不同的ci服务,当有新tag时,会造成两个ci服务都往github release推送相同release编号的生成包,造成第二次推送失败


## 流程
### windows平台:
+ [*appveyor*](https://ci.appveyor.com/projects)注册帐号
+ 将github项目加入appveyor
+ 从`https://github.com/settings/tokens`获取token
+ 使用appveyor官网工具加密上一步的token
  `https://ci.appveyor.com/tools/encrypt`
+ 在项目根目录下编写配置文件,将`auth_token`键名后加上上步的加密后字符串

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
+ 在shell环境下执行git相关命令，创建新的tag标签
```
git add ...
git commit ...
git tag -a v0.0.1
git push origin master --tag
```
+ appveyor页面随即提示有新的build,等待操作完成后,访问github release页面即可发现最新生成包

### macos平台:
+ [*travis*](https://travis-ci.org/)注册帐号
+ 将github项目加入travis
+ 编写`.travis`配置文件

  备注: 此时的配置文件只是包含部分内容, 需要后续步骤补充修改
  
  重要: 配置文件中的`osx_image`字段现阶段指定`xcode8`, 不要使用更高版本，否则code signing报错
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

+ 上步骤完成后, `.travis`配置文件被工具自动修改, 增添了`deploy`字段, 在此基础上继续完善该文件
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
+ 将生成的`p12`加入github源码池中, 并记录好该文件的`https`地址, 如[*Address*](https://github.com/JiangWeiGitHub/wisnucAssistant-mac/raw/master/certificate.p12)
+ 在travis的项目页面上点击`More options`->`Settings`, 在`Environment Variables`下增加两个字段`CSC_LINK`, `CSC_KEY_PASSWORD`, `CSC_LINK`字段的值即为上一步的*.p12文件的https地址, `CSC_KEY_PASSWORD`即为导出`p12`文件输入的密码
+ 在shell环境下执行git相关命令，创建新的tag标签
```
git add ...
git commit ...
git tag -a v0.0.1
git push origin master --tag
```
+ travis页面随即提示有新的build,等待操作完成后,访问github release页面即可发现最新生成包

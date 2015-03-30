a# mogujie Open Source IM App  ![Logo](https://avatars2.githubusercontent.com/u/8542441?v=2&s=200)

[mogujie](http://www.mogujie.com) Open Source IM is aiming to provide another IM solution in your company for colleagues to communicate with each other. 

we've released Win/Mac/Android/iOS  client repositories in github as well as IM server repository.

see all projects in our [mogutt](https://github.com/mogutt) github account page or visit our [website](http://tt.mogu.io/)(Chinease) for more information

## Windows Client Features
* list all colleagues in your company as well as detail profiles like (email addr, title, phone No. etc.)
* support fast search for colleague profile
* support communicating through "Text", "Audio", "Image" messages like [whatsapp](http://www.whatsapp.com/) 
* support creating temporary chat group with multiple people all together
* support permanent chat group created by administrators
* support basic functions such as Emotion、Vibrating screen、File transfer and so on

## How to bulid 
* IDE : VS2013
* Put the TTWinClient project with TTServer project under the same local path
* the solution file relative path of TTWinClient is .\TTWinClient\solution\

## How to use
* By using the setting as follows,please input "http://alpha.mogu.io/" ,so the contributor can debug the project without configuring the servers.
  ![server address config](http://s7.mogucdn.com/b7/pic/141011/8dxwb_ieygmmjymm3dinlemmytambqgiyde_300x120.jpg_468x468.jpg)
* At the login window,use the account "eric" or "tom" with the same password "12345" to login

## The framework of the project
![](http://s8.mogucdn.com/b7/pic/140928/nb8ca_ieydonjsge2tmmrzmmytambqgiyde_803x546.jpg)
####Introduction
    TTWinClient project divided into four layers:
    * first layer:  basic library
    * second layer: logical framework
    * third layer   the business module
    * fourth layer: total teamtalk control module
####basic library：
    * utility:some commonly used API such as: string manipulation,database process ,windows thread library wrap and so on
    * net:commonly used network processing API such as: http client library wrap、asynchronous I/O socket wrap and so on
    * TTProject：for collecting mini core dump
    * duilib：a windowless ui open source library
####TTLogic：
    the framework of TTWinClinet,including as follow:
    * the operation task scheduling 
    * event subscription and publishing
    * asynchronous I/O TCP/IP base on WSAAsyncSelect library of long connection
    * MKO(module key observer) 
    More detailed design document is perfectting

####Modules:
    * FileTransfer：for FileTransfer manage
    * Capture：for screen captrue manage
    * Session：for colleagues or groups session manage
    * Login：for login and network recontent manage
    * UserList：for colleagues manage
    * Message：for sending and receiving message manage
####TeamTalk
    * TeamTalk：total teamtalk control module
    
    

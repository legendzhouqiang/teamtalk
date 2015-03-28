/************************************************************
 * @file         TcpProtocolHeader.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       tcp服务器协议头，包括每个service下的command Id定义
 *
     packet data unit header format:
     length     -- 4 byte
     version    -- 2 byte
     flag       -- 2 byte
     service_id -- 2 byte
     command_id -- 2 byte
     error      -- 2 byte
     reserved   -- 2 byte
 ************************************************************/

#import <Foundation/Foundation.h>
#import <stdint.h>
static const int16_t MODULE_ID_REMOTEBASE = 0x0000U; //与服务器端交互的module id
static const int16_t MODULE_ID_LOCALBASE = 0x4000U;  //本地业务的module id
//SID
enum
{
    DDSERVICE_LOGIN                 = 0x0001,            //登录相关
    MODULE_ID_SESSION                 = 0x0002,          //Session相关
    SERVICE_GROUP                   =0x0004,               //群相关
    DDSERVICE_FRI                   = 3,            //好友相关
    DDSERVICE_MESSAGE               = 0x0003,           //消息相关
    DDSERVICE_USER                  = 7
};

//session

enum{
    RECENT_SESSION_REQ              =   0x0201,    //最近会话请求
    RECENT_SESSION_RES              =   0x0202,     //最近会话返回
    REMOVE_SESSION_REQ              =   0x0206,     //删除最近会话请求
    REMOVE_SESSION_RES              =   0x0207,     //返回删除最近会话请求
    DEPARTINFO_REQ                  =   0x0210,
    DEPARTINFO_RES                  =   0x0211
};

enum
{
    MODULE_ID_NONE              = 0,
    
    //与服务器端交互的module id
    MODULE_ID_LOGIN             = MODULE_ID_REMOTEBASE | 0x0002,    //登陆模块
    MODULE_ID_FRIENDLIST        = MODULE_ID_REMOTEBASE | 0x0003,    //成员列表管理模块
    MODULE_ID_MESSAGE           = MODULE_ID_REMOTEBASE | 0x0004,    //消息管理模块
    MODULE_ID_HTTP              = MODULE_ID_REMOTEBASE | 0x0005,    //HTTP模块
    MODULE_ID_TCPLINK           = MODULE_ID_REMOTEBASE | 0x0006,    //TCP长连接模块
    MODULE_ID_MAIN              = MODULE_ID_REMOTEBASE | 0x0007,    //主窗口模块i
  //  MODULE_ID_SESSION           = MODULE_ID_REMOTEBASE | 0x0050,    //会话模块
   // MODULE_ID_GROUP             = MODULE_ID_REMOTEBASE | 0x0052,    // group module

    MODULE_ID_COMMON            = MODULE_ID_LOCALBASE | 0X002,        //多多公共函数库
};

// 心跳包
enum
{
    DDHEARTBEAT_REQ                 = 1,            
    DDHEARTBEAT_SID                 =0x0007,
    REQ_CID                         =0x0701,
    RES_CID                         =0x0701
};

//MODULE_ID_LOGIN = 1   登陆相关
enum
{
    DDCMD_LOGIN_REQ_MSGSERVER                     = 1,                //获取消息服务器信息接口请求
    DDCMD_LOGIN_RES_MSGSERVER                     = 2,                //返回一个消息服务器的IP和端口
    DDCMD_LOGIN_REQ_USERLOGIN                     = 0x0103,                //用户登录请求
    DDCMD_LOGIN_RES_USERLOGIN                     = 0x0104,                //登陆消息服务器验证结果
    DDCMD_LOGIN_RES_USERLOGOUT                    = 6,                //这个目前不用实现
    DDCMD_LOGIN_KICK_USER                         = 0x0107,                //踢出用户提示.
    CMD_PUSH_TOKEN_REQ                            = 0x0108,           // 发送token
    CMD_PUSH_TOKEN_RES                            = 0x0109,           // 收到token
};

//MODULE_ID_FRIENDLIST = 3 成员列表相关
enum
{
    DDCMD_FRI_RECENT_CONTACTS_RES     = 3,                //最近联系人列表
    DDCMD_FRI_RECENT_CONTACTS_REQ     = 12,               //移除会话请求
    DDCMD_FRI_LIST_DETAIL_INFO_REQ    = 18,               //批量获取用户详细资料
    DDCMD_FRI_LIST_DETAIL_INFO_RES    = 19,               //批量放回用户详细资料
    CID_LOGIN_REQ_LOGINOUT            = 0x0105,	              //
    CID_LOGIN_RES_LOGINOUT            = 0x0106, 	              //
    CID_LOGIN_REQ                     = 0x0101,
    CID_LOGIN_RES                     = 0x0102,           //登录返回
    CMD_FRI_ALL_USER_REQ            = 0x0208,               // 获取公司全部员工信息
    CMD_FRI_ALL_USER_RES            = 0x0209,
    
};

//MODULE_ID_SESSION = 80 消息会话相关
enum
{
    DDCMD_MSG_DATA                        = 0x0301,            //收到聊天消息
    DDCMD_MSG_RECEIVE_DATA_ACK            = 0x0302,            //消息收到确认.  这是收
    CID_MSG_READ_ACK                      = 0x0303,            //消息已读确认
    CID_MSG_READ_NOTIFY                   = 4,            //消息已读通知
    CID_MSG_UNREAD_CNT_REQUEST            = 0x0307,            //请求未读消息计数
    CID_MSG_UNREAD_CNT_RESPONSE           = 0x0308,            //返回自己的未读消息计数
    CID_MSG_LIST_REQUEST                  = 0x0309,            //获取消息队列请求
    CID_MSG_LIST_RESPONSE                 = 0x030a,           //返回消息队列请求
    DDCMD_MSG_GET_2_UNREAD_MSG            = 14,           //返回两人之间的未读消息
    DDCMD_MSG_GET_2_HISTORY_MSG           = 15,           //查询两人之间的历史消息
    MSG_MSG_READ_NOTIFY                   = 0x0304,       //消息被读掉通知
    LASTEST_MSG_ID_REQ                    = 0x030b,         //获取最后一条消息
    LASTEST_MSG_ID_RES                    = 0x030c,
    GET_MSG_BY_IDS_REQ                    = 0x030d,
    GET_MSG_BY_IDS_RES                    = 0x030e
};

//MODULE_ID_USERINFO = 1000
enum
{
    DDCMD_USER_INFO_REQ                     = 0x0204,          //查询用户详情
    DDCMD_USER_INFO_RES                     = 0x0205,           //返回用户详情

};

//群
enum
{
    CMD_ID_GROUP_LIST_REQ               = 0x0401,    // 固定群
    CMD_ID_GROUP_LIST_RES               = 0x0402,
    CMD_ID_GROUP_USER_LIST_REQ          = 0x0403,
    CMD_ID_GROUP_USER_LIST_RES          = 0x0404,
    CMD_ID_GROUP_UNREAD_CNT_REQ         = 5,
    CMD_ID_GROUP_UNREAD_CNT_RES         = 6,
    CMD_ID_GROUP_MSG_READ_ACK           = 11,
    CMD_ID_GROUP_CREATE_TMP_GROUP_REQ   = 0x0405,
    CMD_ID_GROUP_CREATE_TMP_GROUP_RES   = 0x0406,
    CMD_ID_GROUP_CHANGE_GROUP_REQ         = 0x0407,
    CMD_ID_GROUP_CHANGE_GROUP_RES         = 0x0408,
    CMD_ID_GROUP_DIALOG_LIST_REQ        = 16,   // 最近联系群
    CMD_ID_GROUP_DIALOG_LIST_RES        = 17,
    CMD_ID_FIXED_GROUP_CHANGED          = 19,
    CID_GROUP_SHIELD_GROUP_REQUEST      = 0x0409,
    CID_GROUP_SHIELD_GROUP_RESPONSE     = 0x040a,

};
@interface DDTcpProtocolHeader : NSObject

@property (nonatomic,assign) UInt16 version;
@property (nonatomic,assign) UInt16 flag;
@property (nonatomic,assign) UInt16 serviceId;
@property (nonatomic,assign) UInt16 commandId;
@property (nonatomic,assign) UInt16 reserved;
@property (nonatomic,assign) UInt16 error;

@end

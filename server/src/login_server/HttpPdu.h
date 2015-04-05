/*
 * HttpPdu.h
 *
 *  Created on: 2013-10-1
 *      Author: ziteng@mogujie.com
 */

#ifndef HTTPPDU_H_
#define HTTPPDU_H_

#include "util.h"
#include "impdu.h"

// 提示用户的error code, 在errorCode方法里面
enum {
	ERROR_CODE_VALIDATE_FAILED 	= 4005, // 验证用户失败
	ERROR_CODE_KICK_USER 		= 4011,	// 用户账号在其他地方登陆
	ERROR_CODE_USER_OFFLINE 	= 4444, // 用户已经离线
	ERROR_CODE_DISPATCH_FAILED	= 10001, // 分配客服失败
};

// 提示js的error code, 在最外层
enum {
	ERROR_CODE_GENERAL 				= 4000,
	ERROR_CODE_PARSE_PARAM_FAILED 	= 4001,
	ERROR_CODE_PARAM_MISS 			= 4002,
	ERROR_CODE_UUID_NOT_MATCH		= 4003,
	ERROR_CODE_TOKEN_NOT_VALID		= 4004,
	ERROR_CODE_NO_DB_SERVER			= 4005,
	ERROR_CODE_PARSE_JSON_FAILED	= 4006,
	ERROR_CODE_NO_SUCH_USER			= 4007,
	ERROR_CODE_NO_SUCH_METHOD		= 4008,
};


// jsonp parameter parser
class CPostDataParser
{
public:
	CPostDataParser() {}
	virtual ~CPostDataParser() {}

	bool Parse(const char* content);

	char* GetValue(const char* key);
private:
	std::map<std::string, std::string> m_post_map;
};

class CAttachData
{
public:
	CAttachData(uint32_t http_handle, uint32_t uuid, const char* callback_str);	// 序列化
	CAttachData(uchar_t* attach_data, uint32_t attach_len);			// 反序列化
	virtual ~CAttachData() {}

	uchar_t* GetBuffer() {return m_buf.GetBuffer(); }
	uint32_t GetLength() { return m_buf.GetWriteOffset(); }
	uint32_t GetHttpHandle() { return m_http_handle; }
	uint32_t GetUuid() { return m_uuid; }
	char* GetCallback() { return (char*)m_callback.c_str(); }
private:
	uint32_t 	m_http_handle;
	uint32_t 	m_uuid;
	std::string	m_callback;
	CSimpleBuffer m_buf;
};

char* PackErrorResponse(const char* callback, uint32_t code);
char* PackOKResponse(const char* callback);
char* PackLoginResponse(const char* callback, uint32_t result, uint32_t uuid = 0,
		const char* name = NULL, const char* avatar_url = NULL, uint32_t user_type = 0);
char* PackFriendList(const char* callback, const char* type, uint32_t friend_cnt, user_info_t* friend_list);
char* PackFriendList(const char* callback, const char* type, uint32_t friend_cnt, user_info_ext_t* friend_list);
char* PackUnreadMsgCntResponse(const char* callback, uint32_t unread_cnt, UserUnreadMsgCnt_t* unread_list);
char* PackMsgListResponse(const char* callback, const char* action_type, uint32_t display_id,
		uint32_t msg_cnt, server_msg_t* msg_list);
char* PackFriendList(uint32_t friend_cnt, user_info_t* friend_list);
char* PackFriendList(uint32_t friend_cnt, user_info_ext_t* friend_list);
char* PackUnreadMsgCntResponse(uint32_t unread_cnt, UserUnreadMsgCnt_t* unread_list);
char* PackMsgListResponse(uint32_t msg_cnt, server_msg_t* msg_list);
// 查询用户信息
char* PackAddNewUserResponse(const char* callback, uint32_t online_status, uint32_t user_cnt, user_info_t* user_list);
char* PackAddNewUserWithShopInfoResponse(const char* callback, uint32_t online_status, uint32_t user_cnt, user_info_ext_t* user_list);

//group operatoion 
char* PackCreateGroupResponse(uint32_t reqUserId, uint32_t result, uint32_t groupid, const string& groupName, const string& groupDesc, uint32_t userCnt, uint32_t* userIdList, uint32_t memberLimited, uint32_t source_type);
char* PackChangeGroupMemberResponse(uint32_t reqUserId, uint32_t result, uint16_t commandType, uint32_t groupid, uint32_t userCnt, uint32_t* userIdList);
char* PackModifyGroupDescResponse(uint32_t reqUserId, uint32_t result, uint32_t group_id, const string& group_name, const string& group_desc);
char* PackGroupInfoResponse(uint32_t reqUserId, uint32_t result, uint32_t groupid, const string&  groupName, const string& groupDesc, uint32_t groupType, const list<member_info_t>& groupMemberList);
char* PackGroupMemberResponse(uint32_t reqUserId, uint32_t result, uint32_t groupid, const list<member_info_ext_t>& groupMemberList);
char* PackGetCreateGroupListResponse(uint32_t reqUserId, const list<uint32_t>& group_list);

// 以下5个接口返回http回应的body部分，返回的是一个静态内存的指针，
// 所以调用者最好自己保存一份内容(比如用std::string保存)
// 不然会有一些邪恶的bug出现，因为这儿的接口都用了这个静态内存
char* PackMsgData(const char* from_id, const char* to_id, const char* msg_content,
                  uint8_t msgType = MSG_TYPE_TEXT);
char* PackP2PMsg(const char* msg_content);
char* PackStatusChange(uint32_t user_cnt, user_stat_t* user_stat_list);
char* PackErrorCode(uint32_t error_code);
char* PackAddNewUser(const char* action_type, uint32_t shop_id, uint32_t service_type, uint32_t status, user_info_t* user); // 分配客服
char* PackAddNewUserWithShopName(const char* action_type, uint32_t shop_id, uint32_t service_type, uint32_t status, user_info_t* user, const char* shop_name); // add by yugui 分配客服,附带店铺名称

char* PackPollData(const char* callback, const char* payload_data);

// HttpMsgServer查询一组用户在线状态
char* PackOnlineStatus(uint32_t user_cnt, user_stat_t* user_stat_list);
char* PackSendMsgOk();
char* PackTotalQuery(uint32_t total_query);
char* PackOnlineUserCnt(uint32_t online_user_cnt);

/* added by luoning 2014.06.13. */
char* PackUnReadCounterResponse(map<string, uint32_t>* counter_map);
char* PackUnReadCounterResponse(const char* callback, map<string, uint32_t>* counter_map);
char* PackUnReadCounterResponse(map<uint32_t, map<string, uint32_t> > *user_counter_map);
char* PackPushCntRequest(map<string, uint32_t>* counter_map);
/* added end */

char* PackGetLastServiceResponse(uint32_t lastServiceId);

char* PackInsertSysMsgResponse(uint32_t sysMsgId);
char* PackUserBadge(uint32_t userBadgeCnt, user_badge_t* userBadgeList);

string& XSSFilter(string& s);

#endif /* HTTPPDU_H_ */

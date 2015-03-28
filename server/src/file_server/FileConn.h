/*
 * FileConn.h
 *
 *  Created on: 2013-12-9
 *      Author: ziteng@mogujie.com
 */

#ifndef FILECONN_H_
#define FILECONN_H_

#include "imconn.h"
#include "ImPduBase.h"
#include <deque>
#include <pthread.h>
#include <deque>
#include "file_server_util.h"
#include "IM.BaseDefine.pb.h"
using namespace IM::BaseDefine;

#define CONN_TYPE_MSG_SERVER        0
#define CONN_TYPE_CLIENT            1

typedef struct {
	FILE* 		fp;
	string		file_path;
	string		save_path;
	string 		peer_user_id;
	uint32_t	file_size;
	uint32_t	transfer_size;
} file_stat_t;


typedef map<string, file_stat_t*> FileMap_t;

/// yunfan add 2014.8.6


typedef map<std::string, transfer_task_t*> TaskMap_t; // on client connect
/// yunfan add end

class CFileConn : public CImConn
{
public:
	CFileConn();
	virtual ~CFileConn();

	virtual void Close();

	void OnConnect(net_handle_t handle);
	virtual void OnClose();
	virtual void OnTimer(uint64_t curr_tick);

	virtual void OnWrite();
	virtual void HandlePdu(CImPdu* pPdu);
    
private:
    void _HandleHeartBeat(CImPdu* pPdu);
	void _HandleClientFileLoginReq(CImPdu* pPdu);
	
	void _HandleMsgFileTransferReq(CImPdu* pPdu);
    void _HandleClientFileStates(CImPdu* pPdu);
    void _HandleClientFilePullFileReq(CImPdu* pPdu);
	void _HandleClientFilePullFileRsp(CImPdu *pPdu);
	int _StatesNotify(int state, const char* task_id, uint32_t user_id, CImConn* pConn);
	void _HandleGetServerAddressReq(CImPdu* pPdu);
    
	bool _IsAuth() { return m_bAuth; }
    
    /// yunfan add 2014.8.18
private:
    int _PreUpload(const char* task_id);
//  int _DoUpload(const char* task_id);
    /// yunan add end
    

private:
	bool		m_bAuth;
	uint32_t	m_user_id;
	FileMap_t	m_save_file_map;
    TaskMap_t   m_file_task_map;
	list<file_stat_t*>	m_send_file_list;
    uint32_t    m_conntype;         //0: msg_server  1: client
    
};

void init_file_conn(std::list<IM::BaseDefine::IpAddr>&, uint32_t timeout);

#endif /* FILECONN_H_ */

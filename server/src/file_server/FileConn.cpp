/*
 * FileConn.cpp
 *
 *  Created on: 2013-12-9
 *      Author: ziteng@mogujie.com
 */

#include "FileConn.h"
#include <sys/stat.h>
#include "IM.File.pb.h"
#include "IM.Server.pb.h"
#include "IM.Other.pb.h"
#include "public_define.h"
using namespace IM::BaseDefine;

static ConnMap_t g_file_conn_map; // connection with others, on connect insert...
static UserMap_t g_file_user_map; // after user login, insert...
/// yunfan add 2014.8.6
static TaskMap_t g_file_task_map;
static pthread_rwlock_t g_file_task_map_lock = PTHREAD_RWLOCK_INITIALIZER;
/// yunfan add end

static char g_current_save_path[BUFSIZ];

/// yunfan add 2014.8.12
static std::list<IM::BaseDefine::IpAddr> g_addr;
uint16_t g_listen_port = 0;
uint32_t g_task_timeout = 3600;
#define SEGMENT_SIZE 65536
/// yunfan add end

void file_conn_timer_callback(void* callback_data, uint8_t msg, uint32_t handle, void* pParam)
{
	uint64_t cur_time = get_tick_count();
	for (ConnMap_t::iterator it = g_file_conn_map.begin(); it != g_file_conn_map.end(); ) {
		ConnMap_t::iterator it_old = it;
		it++;

		CFileConn* pConn = (CFileConn*)it_old->second;
		pConn->OnTimer(cur_time);
	}
}

void release_task(const char* task_id)
{
    /// should be locked
    if (NULL == task_id) {
        return ;
    }
    
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    TaskMap_t::iterator iter = g_file_task_map.find(task_id);
    if (g_file_task_map.end() == iter) {
        pthread_rwlock_unlock(&g_file_task_map_lock);
        return ;
    }
    transfer_task_t* t = iter->second;
    g_file_task_map.erase(iter);
    pthread_rwlock_unlock(&g_file_task_map_lock);
//    printf("-------ERASE TASK %s----------\n", t->task_id.c_str());
    
    t->lock(__LINE__);
    t->release();
    t->unlock(__LINE__);
    
    delete t;
    t = NULL;
    
    return ;
}

void file_task_timer_callback(void* callback_data, uint8_t msg, uint32_t handle, void* lparam)
{
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    
    for (TaskMap_t::iterator iter = g_file_task_map.begin(); iter != g_file_task_map.end(); ) {
    	// check if self-destroy == true
    	// then delete task
    	if (true == iter->second->self_destroy) {
    		iter->second->lock(__LINE__);
    		iter->second->release();
    		iter->second->unlock(__LINE__);

            if (iter->second) {
                delete iter->second;
                iter->second = NULL;
            }
    		
    		// remove task from map
    		g_file_task_map.erase(iter++);
    	} else { // self-destroy not true
    		// check if timeout
    		long esp = time(NULL) - iter->second->create_time;
    		if (esp > g_task_timeout) {
    			// set self_destory true
    			// then continue;
    			// next round, it will be deleted
    			iter->second->self_destroy = true;
    		}
    		++iter;
    	}
    }

    pthread_rwlock_unlock(&g_file_task_map_lock);
    
    return ;
}

void init_file_conn(std::list<IM::BaseDefine::IpAddr>& q, uint32_t timeout)
{
    /// yunfan add 2014.8.12
    g_addr = q;
    g_task_timeout = timeout;
    /// yunfan add end
    
	char work_path[BUFSIZ];
	if(!getcwd(work_path, BUFSIZ)) {
		log("getcwd failed");
	} else {
		snprintf(g_current_save_path, BUFSIZ, "%s/offline_file", work_path);
	}

	log("save offline files to %s", g_current_save_path);

	int ret = mkdir(g_current_save_path, 0755);
	if ( (ret != 0) && (errno != EEXIST) ) {
		log("!!!mkdir failed to save offline files");
	}

	netlib_register_timer(file_conn_timer_callback, NULL, 1000);
    netlib_register_timer(file_task_timer_callback, NULL, 10000);
}

/// yunfan add 2014.8.7
/// offline file upload
/// file-svr will send pull-data-req to sender
/// then wait for sender's rsp
void* _DoUpload(void* lparam)
{
    if (NULL == lparam) {
        return NULL;
    }
    transfer_task_t* t = reinterpret_cast<transfer_task_t*>(lparam);
    
    t->create_time = time(NULL);
    
    // at begin
    // send 10 data-pull-req
    for (uint32_t cnt = 0; cnt < 1; ++cnt) {
        std::map<uint32_t, upload_package_t*>::iterator iter = t->upload_packages.begin();
        if (t->upload_packages.end() != iter) {
            IM::File::IMFilePullDataReq msg;
            msg.set_task_id(t->task_id);
            msg.set_user_id(t->from_user_id);
            msg.set_trans_mode(::IM::BaseDefine::FILE_TYPE_OFFLINE);
            msg.set_offset(iter->second->offset);
            msg.set_data_size(iter->second->size);
            CImPdu pdu;
            pdu.SetPBMsg(&msg);
            pdu.SetServiceId(SID_FILE);
            pdu.SetCommandId(CID_FILE_PULL_DATA_REQ);
            CFileConn* pConn = (CFileConn*)t->GetConn(t->from_user_id);
            pConn->SendPdu(&pdu);
            log("Pull Data Req");
        }
        ++iter;
    }
    
    // what if there is no rsp?
    // still send req?
    // no!
    // at last, the user will cancel
    // next ver, do change
    while (t->transfered_size != t->upload_packages.size()) {
        if (t->self_destroy) {
        	log("timeout, exit thread, task %s", t->task_id.c_str());
        	return NULL;
        }
        sleep(1);
    }
    

    t->lock(__LINE__);
    
    // write head
    if (NULL == t->file_head) {
        t->file_head = new file_header_t;
    }
    if (NULL == t->file_head) {
        log("create file header failed %s", t->task_id.c_str());
        // beacuse all data in mem
        // it has to be released
        
        /*
        UserMap_t::iterator ator = g_file_user_map.find(t->from_user_id);
        if (g_file_user_map.end() != ator) {
            CFileConn* pConn = (CFileConn*)ator->second;
            pConn->Close();
        }
         */
        CFileConn* pConn = (CFileConn*)t->GetConn(t->from_user_id);
        pConn->Close();
        
        t->self_destroy = true;
        t->unlock(__LINE__);
        return NULL;
        
    }
    t->file_head->set_create_time(time(NULL));
    t->file_head->set_task_id(t->task_id.c_str());
    t->file_head->set_from_user_id(t->from_user_id);
    t->file_head->set_to_user_id(t->to_user_id);
    t->file_head->set_file_name("");
    t->file_head->set_file_size(t->file_size);
    fwrite(t->file_head, 1, sizeof(file_header_t), t->fp);
    
    std::map<uint32_t, upload_package_t*>::iterator itor = t->upload_packages.begin();
    for ( ; itor != t->upload_packages.end(); ++itor) {
        fwrite(itor->second->data, 1, itor->second->size, t->fp);
    }
    
    fflush(t->fp);
    if (t->fp) {
    	fclose(t->fp);
        t->fp = NULL;
    }

    t->unlock(__LINE__);
    return NULL;
}

int generate_id(char* id)
{
    if (NULL == id) {
        return  -1; // invalid param
    }
    
    uuid_t uid = {0};
    uuid_generate(uid);
    if (uuid_is_null(uid)) {
        id = NULL;
        return -2; // uuid generate failed
    }
    uuid_unparse(uid, id);
    
    return 0;
}
/// yunfan add end

CFileConn::CFileConn()
{
	//log("CFileConn\n");
	m_bAuth = false;
	m_user_id = 0;
    m_conntype = CONN_TYPE_MSG_SERVER;
}

CFileConn::~CFileConn()
{
	log("~CFileConn, user_id=%u", m_user_id);

	for (FileMap_t::iterator it = m_save_file_map.begin(); it != m_save_file_map.end(); it++) {
		file_stat_t* file = it->second;
		fclose(file->fp);
		delete file;
	}
	m_save_file_map.clear();
}

void CFileConn::Close()
{
    log("close client, handle %d", m_handle);
    
    m_bAuth = false;
    
	if (m_handle != NETLIB_INVALID_HANDLE) {
		netlib_close(m_handle);
		g_file_conn_map.erase(m_handle);
	}

	if (m_user_id > 0) {
		g_file_user_map.erase(m_user_id);
        m_user_id = 0;
	}

	ReleaseRef();
}

void CFileConn::OnConnect(net_handle_t handle)
{
	/// yunfan modify 2014.8.7
    m_handle = handle;

	g_file_conn_map.insert(make_pair(handle, this));    
	netlib_option(handle, NETLIB_OPT_SET_CALLBACK, (void*)imconn_callback);
	netlib_option(handle, NETLIB_OPT_SET_CALLBACK_DATA, (void*)&g_file_conn_map);

	uint32_t socket_buf_size = NETLIB_MAX_SOCKET_BUF_SIZE;
	netlib_option(handle, NETLIB_OPT_SET_SEND_BUF_SIZE, &socket_buf_size);
	netlib_option(handle, NETLIB_OPT_SET_RECV_BUF_SIZE, &socket_buf_size);
    /// yunfan modify end
}

void CFileConn::OnClose()
{
	log("client onclose: handle=%d", m_handle);
	Close();
}

void CFileConn::OnTimer(uint64_t curr_tick)
{
    if (m_conntype == CONN_TYPE_MSG_SERVER) {
        if (curr_tick > m_last_recv_tick + SERVER_TIMEOUT) {
            log("msg server timeout");
            Close();
        }
    }
    else
    {
        if (curr_tick > m_last_recv_tick + CLIENT_TIMEOUT) {
            log("client timeout, user_id=%u", m_user_id);
            Close();
        }
    }
	
}

void CFileConn::OnWrite()
{
	CImConn::OnWrite();
}

void CFileConn::HandlePdu(CImPdu* pPdu)
{
	switch (pPdu->GetCommandId()) {
        case CID_OTHER_HEARTBEAT:
            _HandleHeartBeat(pPdu);
            break;
        case CID_FILE_LOGIN_REQ:
            _HandleClientFileLoginReq(pPdu);
            break;
        
        case CID_FILE_STATE:
            _HandleClientFileStates(pPdu);
            break ;
        case CID_FILE_PULL_DATA_REQ:
            _HandleClientFilePullFileReq(pPdu);
            break ;
        case CID_FILE_PULL_DATA_RSP:
            _HandleClientFilePullFileRsp( pPdu);
            break ;
        case CID_OTHER_FILE_TRANSFER_REQ:
            _HandleMsgFileTransferReq(pPdu);
            break ;
        case CID_OTHER_FILE_SERVER_IP_REQ:
            _HandleGetServerAddressReq(pPdu);
            break;
        default: 
            log("no such cmd id: %u", pPdu->GetCommandId());
            break;
	}
}

void CFileConn::_HandleHeartBeat(CImPdu *pPdu)
{
    SendPdu(pPdu);
}

void CFileConn::_HandleClientFileLoginReq(CImPdu* pPdu)
{
    // if can not find uuid
    // return invalid uuid
    // if invalid user_id
    // return invalid user
    
    // if ready_to_recv or offline / mobile task
    //   return can_send
    // return ok
    IM::File::IMFileLoginReq msg;
    CHECK_PB_PARSE_MSG(msg.ParseFromArray(pPdu->GetBodyData(), pPdu->GetBodyLength()));
    uint32_t user_id = msg.user_id();
    string task_id = msg.task_id();
    IM::BaseDefine::ClientFileRole mode = msg.file_role();

	m_user_id = user_id;
	log("client login, user_id=%u, handle %d", m_user_id, m_handle);

    // auth done
    m_bAuth = true;
    m_conntype = CONN_TYPE_CLIENT;
    
    IM::File::IMFileLoginRsp msg2;
    msg2.set_result_code(1);
    msg2.set_task_id(task_id);
    CImPdu pdu;
    pdu.SetPBMsg(&msg2);
    pdu.SetServiceId(SID_FILE);
    pdu.SetCommandId(CID_FILE_LOGIN_RES);
    pdu.SetSeqNum(pPdu->GetSeqNum());
    
    // create task for offline download
    if (IM::BaseDefine::CLIENT_OFFLINE_DOWNLOAD == mode) {
        // create a thread // insert into a queue, multi-threads handle the queue
        // find file
        // send file
        transfer_task_t* t = new transfer_task_t;
        if (NULL == t) {
            SendPdu(&pdu);
            Close();
            log("create task failed for task id %s, user %d", task_id.c_str(), m_user_id);
            return; // create task failed
        }
        t->task_id = task_id;
        t->to_user_id = m_user_id;
        t->create_time = time(NULL);
        pthread_rwlock_wrlock(&g_file_task_map_lock);
        g_file_task_map.insert(std::make_pair(task_id.c_str(), t));
        pthread_rwlock_unlock(&g_file_task_map_lock);
    }
    
    // check task
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    TaskMap_t::iterator iter = g_file_task_map.find(task_id.c_str());
    if (g_file_task_map.end() == iter) {
        // failed to find task
        // return invaild task id
        pthread_rwlock_unlock(&g_file_task_map_lock);
        SendPdu(&pdu);
        Close(); // invalid user for task
        log("check task id failed, user_id = %u, request taks id %s", m_user_id, task_id.c_str());
        return;
    }
    transfer_task_t* t = iter->second;
    pthread_rwlock_unlock(&g_file_task_map_lock);
    
    // check user
    if (t->from_user_id != m_user_id && t->to_user_id != m_user_id) {
        // invalid user
        // return error
        SendPdu(&pdu);
        Close();
        log("invalid user %u for task %s", m_user_id, task_id.c_str());
        return;
    }
    
    // prepare for offline upload
    if (CLIENT_OFFLINE_UPLOAD == mode) {
        int iret = _PreUpload(task_id.c_str());
        if (0 > iret) {
            SendPdu(&pdu);
            Close();
            log("preload faild for task %s, err %d", task_id.c_str(), iret);
            return;
        }
    }
    
    if (t->from_user_id == m_user_id) {
        t->from_conn = this;
    }
    if (t->to_user_id == m_user_id) {
        t->to_conn = this;
    }
    
    // send result
    msg2.set_result_code(0);
    CImPdu pdu2;
    pdu2.SetPBMsg(&msg2);
    pdu2.SetServiceId(SID_FILE);
    pdu2.SetCommandId(CID_FILE_LOGIN_RES);
    pdu2.SetSeqNum(pPdu->GetSeqNum());
	SendPdu(&pdu2); // login succeed
    
    /// yunfan add 2014.8.12
    // 2014.8.14
    // record state
    if (m_user_id == t->from_user_id) {
        t->ready_to_send = true;
    }
    if (m_user_id == t->to_user_id) {
        t->ready_to_recv = true;
    }
    // notify that the peet is ready
    if ( (m_user_id == t->to_user_id && \
          t->ready_to_send) || \
        (m_user_id == t->from_user_id && \
         t->ready_to_recv)){
        // send peer-ready state to recver
        _StatesNotify(IM::BaseDefine::CLIENT_FILE_PEER_READY, task_id.c_str(), m_user_id, t->GetConn(m_user_id));
        log("nofity recver %d task %s can recv", m_user_id, task_id.c_str());
    }
    
    // create a thread // insert into a queue, multi-threads handle the queue
    // send to client PULLDATA msg
    // recv and write file
    if (IM::BaseDefine::CLIENT_OFFLINE_UPLOAD == mode) {
        // check thread id
        pthread_create(&t->worker, NULL, _DoUpload, t);
        log("create thread for offline upload task %s user %d thread id %d", task_id.c_str(), m_user_id, t->worker);
    }
    /// yunfan add end

    return;
}

/// yunfan add 2014.8.6
void CFileConn::_HandleMsgFileTransferReq(CImPdu* pPdu)
{
    // if realtime transfer
    // new realtime_task
    // generate uuid
    // copy userid_1 userid_2
    // time_t = time(null);
    // return uuid
    // else new offline_task
    // generate uuid
    // copy user_1
    // copy file_size
    // time_t = time(null)
    // return uuid
    
    // create task for:
    // realtime transfer and offline upload
    
    IM::Server::IMFileTransferReq msg;
    CHECK_PB_PARSE_MSG(msg.ParseFromArray(pPdu->GetBodyData(), pPdu->GetBodyLength()));

    
    uint32_t from_id = msg.from_user_id();
    uint32_t to_id = msg.to_user_id();
    
    IM::Server::IMFileTransferRsp msg2;
    msg2.set_result_code(1);
    msg2.set_from_user_id(from_id);
    msg2.set_to_user_id(to_id);
    msg2.set_file_name(msg.file_name());
    msg2.set_file_size(msg.file_size());
    msg2.set_task_id("");
    msg2.set_trans_mode(msg.trans_mode());
    msg2.set_attach_data(msg.attach_data());
    CImPdu pdu;
    pdu.SetPBMsg(&msg2);
    pdu.SetServiceId(SID_OTHER);
    pdu.SetCommandId(CID_OTHER_FILE_TRANSFER_RSP);
    pdu.SetSeqNum(pPdu->GetSeqNum());
    char task_id[64] = {0};
    int iret = generate_id(task_id);
    if (0 > iret || NULL == task_id) {
        SendPdu(&pdu);
        log("create task id failed");
        return; // errno create task id failed 1
    }
    
    // new task and add to task_map
    transfer_task_t* task = new transfer_task_t;
    if (NULL == task) {
        // log new failed
        // return error
        SendPdu(&pdu);
        Close(); // close connection with msg svr
        log("create task failed");
        return; // create task failed
    }
    
    task->transfer_mode = msg.trans_mode();
    task->task_id = task_id;
    task->from_user_id = from_id;
    task->to_user_id = to_id;
    task->file_size = msg.file_size();
    task->create_time = time_t(NULL);

    // read cfg file
    msg2.set_result_code(0);
    pdu.SetPBMsg(&msg2);
	SendPdu(&pdu);
    
    task->create_time = time(NULL);
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    g_file_task_map.insert(make_pair((char*)task->task_id.c_str(), task));
    pthread_rwlock_unlock(&g_file_task_map_lock);
    
    log("create task succeed, task id %s, task type %d, from user %d, to user %d", task->task_id.c_str(), task->transfer_mode, task->from_user_id, task->to_user_id);
    
    return;
}

void CFileConn::_HandleClientFileStates(CImPdu* pPdu)
{
    // switch state
    // case ready_to_recv
    //     if sender_on
    //       tell sender can_send
    //     else update state
    // case cancel
    //      notify ohter node cancel
    //      close socket
    // case dnoe
    //      notify recver done
    //      close socket

    if (!_IsAuth()) {
		return;
	}
    
    IM::File::IMFileState msg;
    CHECK_PB_PARSE_MSG(msg.ParseFromArray(pPdu->GetBodyData(), pPdu->GetBodyLength()));

    
    string task_id = msg.task_id();
    uint32_t user_id = msg.user_id();
    uint32_t file_stat = msg.state();
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    TaskMap_t::iterator iter = g_file_task_map.find((char*)task_id.c_str());
    if (g_file_task_map.end() == iter) {
        pthread_rwlock_unlock(&g_file_task_map_lock);
        return; // invalid task id
    }
    transfer_task_t* t = iter->second;
    pthread_rwlock_unlock(&g_file_task_map_lock);
    
    t->lock(__LINE__);
    if (t->from_user_id != user_id && t->to_user_id != user_id) {
        log("invalid user_id %d for task %s", user_id, task_id.c_str());
        t->unlock(__LINE__);
        return;
    }
    t->unlock(__LINE__);
    
    switch (file_stat) {
        case IM::BaseDefine::CLIENT_FILE_CANCEL:
        case IM::BaseDefine::CLIENT_FILE_DONE:
        case IM::BaseDefine::CLIENT_FILE_REFUSE:
        {
            // notify other client
            CFileConn* pConn = (CFileConn*)t->GetOpponentConn(user_id);
            pConn->SendPdu(pPdu);
            
            // release
            log("task %s %d by user_id %d notify %d, erased", task_id.c_str(), file_stat, user_id, t->GetOpponent(user_id));
            
            t->self_destroy = true;
            break;
        }
            
        default:
            break;
    }
    
    return;
}

// data handler async
// if uuid not found
// return invalid uuid and close socket
// if offline or mobile task
// check if file size too large, write data and ++size
// if realtime task
// if transfer data

void CFileConn::_HandleClientFilePullFileReq(CImPdu *pPdu)
{
    if (!_IsAuth()) {
		return;
	}
    
    IM::File::IMFilePullDataReq msg;
    CHECK_PB_PARSE_MSG(msg.ParseFromArray(pPdu->GetBodyData(), pPdu->GetBodyLength()));

	uint32_t user_id = msg.user_id();
    string task_id = msg.task_id();
    uint32_t mode = msg.trans_mode();
	uint32_t offset = msg.offset();
	uint32_t datasize = msg.data_size();
    
    IM::File::IMFilePullDataRsp msg2;
    msg2.set_result_code(1);
    msg2.set_task_id(task_id);
    msg2.set_user_id(user_id);
    msg2.set_offset(offset);
    msg2.set_data("");
    CImPdu pdu;
    pdu.SetPBMsg(&msg2);
    pdu.SetServiceId(SID_FILE);
    pdu.SetCommandId(CID_FILE_PULL_DATA_RSP);
    pdu.SetSeqNum(pPdu->GetSeqNum());
    // since the task had been created when the recver logged-in
    // we can find task in g_file_task_map here
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    TaskMap_t::iterator iter = g_file_task_map.find(task_id.c_str());
    if (g_file_task_map.end() == iter) {
        // invalid task id
        pthread_rwlock_unlock(&g_file_task_map_lock);
        log("invalid task id %s ", task_id.c_str());
        SendPdu(&pdu);
        return;
    }
    transfer_task_t* t = iter->second;
    pthread_rwlock_unlock(&g_file_task_map_lock);
    
    t->lock(__LINE__);
    
    t->create_time = time(NULL);
    
    if (t->from_user_id != user_id /*for the realtime recver*/ && t->to_user_id != user_id /*for the offline download*/) {
        // invalid user
        log("illieage user %d for task %s", user_id, task_id.c_str());
        SendPdu(&pdu);
        
        t->unlock(__LINE__);
        return;
    }
    
    switch (mode) {
        case IM::BaseDefine::FILE_TYPE_ONLINE: // transfer request to sender
        {
            CFileConn* pConn = (CFileConn*)t->GetOpponentConn(user_id);
            pConn->SendPdu(pPdu);
            break;
        }
        case IM::BaseDefine::FILE_TYPE_OFFLINE: // for the offline download
        {
            // find file use task id
            // send header info to user
            // send data
            // save path manager not used
            
            // save transfered info into task
            // like FILE*
            // transfered size
            
            
            // haven't been opened
            size_t size = 0;
            if (NULL == t->fp) {
                char save_path[BUFSIZ] = {0};
                snprintf(save_path, BUFSIZ, "%s/%d", g_current_save_path, user_id); // those who can only get files under their user_id-dir
                
                int ret = mkdir(save_path, 0755);
                if ( (ret != 0) && (errno != EEXIST) ) {
                    log("mkdir failed for path: %s", save_path);
                    SendPdu(&pdu);
                    t->unlock(__LINE__);
                    return;
                }
                
                strncat(save_path, "/", BUFSIZ);
                strncat(save_path, task_id.c_str(), BUFSIZ); // use task_id as file name, in case of same-name file
                
                // open at first time
                t->fp = fopen(save_path, "rb");  // save fp
                if (!t->fp) {
                    log("can not open file");
                    SendPdu(&pdu);
                    
                    t->unlock(__LINE__);
                    return;
                }
                
                // read head at open
                if (NULL == t->file_head) {
                    t->file_head = new file_header_t;
                    if (NULL == t->file_head) {
                        // close to ensure next time will new file-header again
                        log("read file head failed.");

                        fclose(t->fp);
                        SendPdu(&pdu);
                        
                        t->unlock(__LINE__);
                        return;
                    }
                }
                
                size = fread(t->file_head, 1, sizeof(file_header_t), t->fp); // read header
                if (sizeof(file_header_t) > size) {
                    // close to ensure next time will read again
                    log("read file head failed.");
                    fclose(t->fp); // error to get header
                    SendPdu(&pdu);
                    
                    t->unlock(__LINE__);
                    return;
                } // the header won't be sent to recver, because the msg svr had already notified it.
                // if the recver needs to check it, it could be helpful
                // or sometime later, the recver needs it in some way.
            }
            
            // read data and send based on offset and datasize.
            char* tmpbuf = new char[datasize];
            if (NULL == tmpbuf) {
                // alloc mem failed
                log("alloc mem failed.");
                SendPdu(&pdu);
                t->unlock(__LINE__);
                return;
            }
            memset(tmpbuf, 0, datasize);
            
            // offset file_header_t
            int iret = fseek(t->fp, sizeof(file_header_t) + offset, SEEK_SET); // read after file_header_t
            if (0 != iret) {
                log("seek offset failed.");
                SendPdu(&pdu);
                delete[] tmpbuf;
                
                t->unlock(__LINE__);
                return;
                // offset failed
            }
            size = fread(tmpbuf, 1, datasize, t->fp);
            msg2.set_data(tmpbuf, size);
            CImPdu pdu2;
            pdu2.SetPBMsg(&msg2);
            pdu2.SetServiceId(SID_FILE);
            pdu2.SetCommandId(CID_FILE_PULL_DATA_RSP);
            pdu2.SetSeqNum(pPdu->GetSeqNum());
            pdu2.SetSeqNum(pPdu->GetSeqNum());
            SendPdu(&pdu2);
            delete[] tmpbuf;
            
            t->transfered_size += size; // record transfered size for next time offset
            if (0 == size) {
                fclose(t->fp);
                t->fp = NULL;
                
                _StatesNotify(CLIENT_FILE_DONE, task_id.c_str(), user_id, this);
                Close();
                
                t->self_destroy = true;
                t->unlock(__LINE__);
                return;
            }
            
            break;
        }
        default:
            break;
    }
  
    t->unlock(__LINE__);
    return;
}

void CFileConn::_HandleClientFilePullFileRsp(CImPdu *pPdu)
{
    if (!_IsAuth()) {
		return;
	}
    
    IM::File::IMFilePullDataRsp msg;
    CHECK_PB_PARSE_MSG(msg.ParseFromArray(pPdu->GetBodyData(), pPdu->GetBodyLength()));

	uint32_t user_id = msg.user_id();
    string task_id = msg.task_id();
	uint32_t offset = msg.offset();
	uint32_t data_size = msg.data().length();
    
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    TaskMap_t::iterator iter = g_file_task_map.find(task_id.c_str());
    if (g_file_task_map.end() == iter) {
        // invalid task id
        pthread_rwlock_unlock(&g_file_task_map_lock);
        return;
    }
    transfer_task_t* t = iter->second;
    pthread_rwlock_unlock(&g_file_task_map_lock);
    
    t->lock(__LINE__);
    
    t->create_time = time(NULL);
    
    if (t->from_user_id != user_id && t->to_user_id != user_id) {
        // invalid user
        t->unlock(__LINE__);
        return;
    }
    
    switch (t->transfer_mode) {
        case FILE_TYPE_ONLINE: // transfer request to sender
        {
            CFileConn* pConn = (CFileConn*)t->GetOpponentConn(user_id);
            pConn->SendPdu(pPdu); /// send to recver
            break;
        }
        case FILE_TYPE_OFFLINE: /// this is the response to the server pull-data-req
        {
            if (t->upload_packages.size() <= 0) {
                log("FATAL ERROR");
                t->unlock(__LINE__);
                return;
            }
            
            // check if data size ok
            std::map<uint32_t, upload_package_t*>::iterator itPacks = t->upload_packages.find(offset);
            if (t->upload_packages.end() != itPacks) { // offset right
                
                // check if data size ok
                if (data_size != itPacks->second->size) {
                    // the rsp's data size is different from req's
                    // refuse it or dynamic adjust
                    // do not adjust now, maybe later
                    uint32_t offset = itPacks->second->offset;
                    uint32_t size = itPacks->second->size;
                    // resend req
                    IM::File::IMFilePullDataReq msg2;
                    msg2.set_task_id(task_id);
                    msg2.set_user_id(user_id);
                    msg2.set_trans_mode((::IM::BaseDefine::FileType)t->transfer_mode);
                    msg2.set_offset(offset);
                    msg2.set_data_size(size);
                    CImPdu pdu;
                    pdu.SetPBMsg(&msg2);
                    pdu.SetServiceId(SID_FILE);
                    pdu.SetCommandId(CID_FILE_PULL_DATA_REQ);
                    SendPdu(&pdu);
                    log("size not match");

                    t->unlock(__LINE__);
                    return;
                }
                
                // check if data-ptr OK
                if (NULL == itPacks->second->data) {
                    itPacks->second->data = new char[itPacks->second->size];
                    if (NULL == itPacks->second->data) {
                        uint32_t offset = itPacks->second->offset;
                        uint32_t size = itPacks->second->size;
                        
                        log("alloc mem failed");
                        // resend req
                        IM::File::IMFilePullDataReq msg2;
                        msg2.set_task_id(task_id);
                        msg2.set_user_id(user_id);
                        msg2.set_trans_mode((::IM::BaseDefine::FileType)t->transfer_mode);
                        msg2.set_offset(offset);
                        msg2.set_data_size(size);
                        CImPdu pdu;
                        pdu.SetPBMsg(&msg2);
                        pdu.SetServiceId(SID_FILE);
                        pdu.SetCommandId(CID_FILE_PULL_DATA_REQ);
                        SendPdu(&pdu);
                        t->unlock(__LINE__);
                        return;
                    }
                }
                
                // copy data
                memset(itPacks->second->data, 0,  itPacks->second->size);
                memcpy(itPacks->second->data, msg.data().c_str(), msg.data().length());
                ++t->transfered_size;
            }
            
            // find which segment hasn't got data yet
            bool bFound = false;
            std::map<uint32_t, upload_package_t*>::iterator itor = t->upload_packages.begin();
            for ( ; itor != t->upload_packages.end(); ++itor) {
                if (NULL == itor->second->data) {
                    bFound = true;
                    break;
                }
            }
            if (!bFound) {
                // all packages recved
                _StatesNotify(IM::BaseDefine::CLIENT_FILE_DONE, task_id.c_str(), user_id, t->GetConn(user_id));
                Close();

                t->unlock(__LINE__);
                return;
            }
            // prepare to send req for this segment
            uint32_t next_offset = itor->second->offset;
            uint32_t next_size = itor->second->size;
            
            // send pull-data-req
            IM::File::IMFilePullDataReq msg2;
            msg2.set_task_id(task_id);
            msg2.set_user_id(user_id);
            msg2.set_trans_mode((::IM::BaseDefine::FileType)t->transfer_mode);
            msg2.set_offset(next_offset);
            msg2.set_data_size(next_size);
            CImPdu pdu;
            pdu.SetPBMsg(&msg2);
            pdu.SetServiceId(SID_FILE);
            pdu.SetCommandId(CID_FILE_PULL_DATA_REQ);
            SendPdu(&pdu);
            break;
        }
        default:
            break;
    }
    
    t->unlock(__LINE__);
    return;
}

int CFileConn::_StatesNotify(int state, const char* task_id, uint32_t user_id, CImConn* conn)
{
    CFileConn* pConn = (CFileConn*)conn;
    IM::File::IMFileState msg;
    msg.set_state((::IM::BaseDefine::ClientFileState)state);
    msg.set_task_id(task_id);
    msg.set_user_id(user_id);
    CImPdu pdu;
    pdu.SetPBMsg(&msg);
    
    pConn->SendPdu(&pdu);
    log("notify to user %d state %d task %s", user_id, state, task_id);
    return 0;
}

int CFileConn::_PreUpload(const char* task_id)
{
    pthread_rwlock_wrlock(&g_file_task_map_lock);
    TaskMap_t::iterator iter = g_file_task_map.find(task_id);
    if (g_file_task_map.end() == iter) {
        pthread_rwlock_unlock(&g_file_task_map_lock);
        log("failed to find task %s in task map", task_id);
        return -1;
    }
    transfer_task_t* t = iter->second;
    pthread_rwlock_unlock(&g_file_task_map_lock);
    
    char save_path[BUFSIZ];
    std::string str_user_id = idtourl(t->to_user_id);
    snprintf(save_path, BUFSIZ, "%s/%s", g_current_save_path, str_user_id.c_str());
    int ret = mkdir(save_path, 0755);
    if ( (ret != 0) && (errno != EEXIST) ) {
        log("mkdir failed for path: %s", save_path);
        
        t->self_destroy = true;
        return -2;
    }
    
    // save as g_current_save_path/to_id_url/task_id
    strncat(save_path, "/", BUFSIZ);
    strncat(save_path, t->task_id.c_str(), BUFSIZ);
    
    t->fp = fopen(save_path, "ab+");
    if (!t->fp) {
        log("open file for write failed");
        
        t->self_destroy = true;
        return -3;
    }
    
    uint32_t total_packages = t->file_size / SEGMENT_SIZE;
    for (uint32_t cnt = 0; cnt < total_packages; ++cnt) {
        upload_package_t* package = new upload_package_t(cnt, cnt * SEGMENT_SIZE, SEGMENT_SIZE);
        if (NULL == t) {
            log("create upload packages failed");
            
            t->self_destroy = true;
            return -4;
        }
        t->upload_packages.insert(std::make_pair(package->offset, package));
    }
    
    uint32_t last_piece = t->file_size % SEGMENT_SIZE;
    if (last_piece) {
        total_packages += 1;
        upload_package_t* package = new upload_package_t(t->upload_packages.size(), t->file_size - last_piece, last_piece);
        if (NULL == package) {
            log("create upload package failed");
            
            t->self_destroy = true;
            return -5;
        }
        t->upload_packages.insert(std::make_pair(package->offset, package));
    }

    return 0;
}

void CFileConn::_HandleGetServerAddressReq(CImPdu* pPdu)
{
    IM::Server::IMFileServerIPRsp msg;
    for (auto ip_addr_tmp : g_addr)
    {
        auto ip_addr = msg.add_ip_addr_list();
        *ip_addr = ip_addr_tmp;
    }
    CImPdu pdu;
    pdu.SetPBMsg(&msg);
    pdu.SetServiceId(SID_OTHER);
    pdu.SetCommandId(CID_OTHER_FILE_SERVER_IP_RSP);
    pdu.SetSeqNum(pPdu->GetSeqNum());
	SendPdu(&pdu);
	return;
}
/// yunfan add end

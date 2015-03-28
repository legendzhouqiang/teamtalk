/******************************************************************************* 
 *  @file      Operation.cpp 2014\12\23 13:35:34 $
 *  @author    ¿ìµ¶<kuaidao@mogujie.com>
 *  @brief     
 ******************************************************************************/

#include "GlobalConfig.h"
#include "network/Exception.h"
#include "network/Operation.h"
#include "yaolog/yaolog.h"
/******************************************************************************/
NAMESPACE_BEGIN(imcore)

// -----------------------------------------------------------------------------
//  Operation: Public, Constructor

Operation::Operation()
:m_state(OPERATION_IDLE)
{

}

Operation::Operation(const std::string& name)
:m_state(OPERATION_IDLE)
,m_name(name.c_str())
{

}

// -----------------------------------------------------------------------------
//  Operation: Public, Destructor

Operation::~Operation()
{

}

void Operation::process()
{
	try
	{
		m_state = OPERATION_RUNNING;
		processOpertion();
	}
	catch (Exception& exc)
	{
		assert(false);
		LOG__(ERR, _T("process exception,reason:%s"),exc.what());
	}
	catch (std::exception& exc)
	{
		assert(false);
		LOG__(ERR, _T("process exception,reason:%s"), exc.what());
	}
	catch (...)
	{
		assert(false);
		LOG__(ERR, _T("process unknown exception"));
	}
	m_state = OPERATION_FINISHED;
}

void Operation::release()
{
	delete this;
}

NAMESPACE_END(imcore)
/******************************************************************************/
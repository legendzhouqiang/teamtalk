/*================================================================
*   Copyright (C) 2015 All rights reserved.
*   
*   文件名称：test.cpp
*   创 建 者：Zhang Yuanhao
*   邮    箱：bluefoxah@gmail.com
*   创建日期：2015年03月17日
*   描    述：
*
#include "test.h"
================================================================*/
#include <iostream>
#include <stdio.h>

#include "security.h"

using namespace std;
int main()
{
    string msg_data("QhGXlpFjvMFUNrtl1aaPzA==");
    char* msg_out = NULL;
    uint32_t msg_out_len = 0;
    if (DecryptMsg(msg_data.c_str(), msg_data.length(), &msg_out, msg_out_len) == 0)
    {
        msg_data = string(msg_out, msg_out_len);
    }
    else
    {
        printf("decrypt msg failed\n");
        return -1;
    }
    printf("%s\n", msg_out);
    Free(msg_out);
    return 0;
}
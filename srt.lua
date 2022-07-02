-- Copyright (c) 2003-2012 Apple Inc. All rights reserved.
-- Copyright (C) 2016 The Android Open Source Project
-- Copyright (c) 2018 Haivision Systems Inc.
-- Copyright 2022, Mansour Moufid <mansourmoufid@gmail.com>

local srt = {}

local ffi = require('ffi')

local status, _ = pcall(function () ffi.load('android') end)
if status then
    ffi.os = 'Android'
end

local libsrt = ffi.load('srt')

if ffi.os == 'OSX' then
    assert(ffi.abi('64bit'))
    ffi.cdef([[
        typedef signed char __int8_t;
        typedef unsigned char __uint8_t;
        typedef short __int16_t;
        typedef unsigned short __uint16_t;
        typedef int __int32_t;
        typedef unsigned int __uint32_t;
        typedef long long __int64_t;
        typedef unsigned long long __uint64_t;
        typedef __uint8_t sa_family_t;
        struct sockaddr_storage {
            __uint8_t ss_len;
            sa_family_t ss_family;
            char __ss_pad1[((sizeof(__int64_t)) - sizeof(__uint8_t) - sizeof(sa_family_t))];
            __int64_t __ss_align;
            char __ss_pad2[(128 - sizeof(__uint8_t) - sizeof(sa_family_t) - ((sizeof(__int64_t)) - sizeof(__uint8_t) - sizeof(sa_family_t)) - (sizeof(__int64_t)))];
        };
    ]])
end
if ffi.os == 'Android' then
    ffi.cdef([[
        typedef unsigned short sa_family_t;
        struct sockaddr_storage {
            union {
                struct {
                    sa_family_t ss_family;
                    char __data[128 - sizeof(sa_family_t)];
                };
                void* __align;
            };
        };
    ]])
end

ffi.cdef([[
    typedef void SRT_LOG_HANDLER_FN(void* opaque, int level, const char* file, int line, const char* area, const char* message);
    typedef int32_t SRTSOCKET;
    static const int32_t SRTGROUP_MASK = (1 << 30);
    typedef int SYSSOCKET;
    typedef SYSSOCKET UDPSOCKET;
    typedef enum SRT_SOCKSTATUS {
       SRTS_INIT = 1,
       SRTS_OPENED,
       SRTS_LISTENING,
       SRTS_CONNECTING,
       SRTS_CONNECTED,
       SRTS_BROKEN,
       SRTS_CLOSING,
       SRTS_CLOSED,
       SRTS_NONEXIST
    } SRT_SOCKSTATUS;
    typedef enum SRT_SOCKOPT {
       SRTO_MSS = 0,
       SRTO_SNDSYN = 1,
       SRTO_RCVSYN = 2,
       SRTO_ISN = 3,
       SRTO_FC = 4,
       SRTO_SNDBUF = 5,
       SRTO_RCVBUF = 6,
       SRTO_LINGER = 7,
       SRTO_UDP_SNDBUF = 8,
       SRTO_UDP_RCVBUF = 9,
       SRTO_RENDEZVOUS = 12,
       SRTO_SNDTIMEO = 13,
       SRTO_RCVTIMEO = 14,
       SRTO_REUSEADDR = 15,
       SRTO_MAXBW = 16,
       SRTO_STATE = 17,
       SRTO_EVENT = 18,
       SRTO_SNDDATA = 19,
       SRTO_RCVDATA = 20,
       SRTO_SENDER = 21,
       SRTO_TSBPDMODE = 22,
       SRTO_LATENCY = 23,
       SRTO_INPUTBW = 24,
       SRTO_OHEADBW,
       SRTO_PASSPHRASE = 26,
       SRTO_PBKEYLEN,
       SRTO_KMSTATE,
       SRTO_IPTTL = 29,
       SRTO_IPTOS,
       SRTO_TLPKTDROP = 31,
       SRTO_SNDDROPDELAY = 32,
       SRTO_NAKREPORT = 33,
       SRTO_VERSION = 34,
       SRTO_PEERVERSION,
       SRTO_CONNTIMEO = 36,
       SRTO_DRIFTTRACER = 37,
       SRTO_MININPUTBW = 38,
       SRTO_SNDKMSTATE = 40,
       SRTO_RCVKMSTATE,
       SRTO_LOSSMAXTTL,
       SRTO_RCVLATENCY,
       SRTO_PEERLATENCY,
       SRTO_MINVERSION,
       SRTO_STREAMID,
       SRTO_CONGESTION,
       SRTO_MESSAGEAPI,
       SRTO_PAYLOADSIZE,
       SRTO_TRANSTYPE = 50,
       SRTO_KMREFRESHRATE,
       SRTO_KMPREANNOUNCE,
       SRTO_ENFORCEDENCRYPTION,
       SRTO_IPV6ONLY,
       SRTO_PEERIDLETIMEO,
       SRTO_BINDTODEVICE,
       SRTO_GROUPCONNECT,
       SRTO_GROUPMINSTABLETIMEO,
       SRTO_GROUPTYPE,
       SRTO_PACKETFILTER = 60,
       SRTO_RETRANSMITALGO = 61,
       SRTO_E_SIZE
    } SRT_SOCKOPT;
    enum SRT_SOCKOPT_DEPRECATED
    {
        SRTO_DEPRECATED_END = 0
    };
    typedef enum SRT_TRANSTYPE
    {
        SRTT_LIVE,
        SRTT_FILE,
        SRTT_INVALID
    } SRT_TRANSTYPE;
    static const int SRT_LIVE_DEF_PLSIZE = 1316;
    static const int SRT_LIVE_MAX_PLSIZE = 1456;
    static const int SRT_LIVE_DEF_LATENCY_MS = 120;
    struct CBytePerfMon
    {
       int64_t msTimeStamp;
       int64_t pktSentTotal;
       int64_t pktRecvTotal;
       int pktSndLossTotal;
       int pktRcvLossTotal;
       int pktRetransTotal;
       int pktSentACKTotal;
       int pktRecvACKTotal;
       int pktSentNAKTotal;
       int pktRecvNAKTotal;
       int64_t usSndDurationTotal;
       int pktSndDropTotal;
       int pktRcvDropTotal;
       int pktRcvUndecryptTotal;
       uint64_t byteSentTotal;
       uint64_t byteRecvTotal;
       uint64_t byteRcvLossTotal;
       uint64_t byteRetransTotal;
       uint64_t byteSndDropTotal;
       uint64_t byteRcvDropTotal;
       uint64_t byteRcvUndecryptTotal;
       int64_t pktSent;
       int64_t pktRecv;
       int pktSndLoss;
       int pktRcvLoss;
       int pktRetrans;
       int pktRcvRetrans;
       int pktSentACK;
       int pktRecvACK;
       int pktSentNAK;
       int pktRecvNAK;
       double mbpsSendRate;
       double mbpsRecvRate;
       int64_t usSndDuration;
       int pktReorderDistance;
       double pktRcvAvgBelatedTime;
       int64_t pktRcvBelated;
       int pktSndDrop;
       int pktRcvDrop;
       int pktRcvUndecrypt;
       uint64_t byteSent;
       uint64_t byteRecv;
       uint64_t byteRcvLoss;
       uint64_t byteRetrans;
       uint64_t byteSndDrop;
       uint64_t byteRcvDrop;
       uint64_t byteRcvUndecrypt;
       double usPktSndPeriod;
       int pktFlowWindow;
       int pktCongestionWindow;
       int pktFlightSize;
       double msRTT;
       double mbpsBandwidth;
       int byteAvailSndBuf;
       int byteAvailRcvBuf;
       double mbpsMaxBW;
       int byteMSS;
       int pktSndBuf;
       int byteSndBuf;
       int msSndBuf;
       int msSndTsbPdDelay;
       int pktRcvBuf;
       int byteRcvBuf;
       int msRcvBuf;
       int msRcvTsbPdDelay;
       int pktSndFilterExtraTotal;
       int pktRcvFilterExtraTotal;
       int pktRcvFilterSupplyTotal;
       int pktRcvFilterLossTotal;
       int pktSndFilterExtra;
       int pktRcvFilterExtra;
       int pktRcvFilterSupply;
       int pktRcvFilterLoss;
       int pktReorderTolerance;
       int64_t pktSentUniqueTotal;
       int64_t pktRecvUniqueTotal;
       uint64_t byteSentUniqueTotal;
       uint64_t byteRecvUniqueTotal;
       int64_t pktSentUnique;
       int64_t pktRecvUnique;
       uint64_t byteSentUnique;
       uint64_t byteRecvUnique;
    };
    enum CodeMajor
    {
        MJ_UNKNOWN = -1,
        MJ_SUCCESS = 0,
        MJ_SETUP = 1,
        MJ_CONNECTION = 2,
        MJ_SYSTEMRES = 3,
        MJ_FILESYSTEM = 4,
        MJ_NOTSUP = 5,
        MJ_AGAIN = 6,
        MJ_PEERERROR = 7
    };
    enum CodeMinor
    {
        MN_NONE = 0,
        MN_TIMEOUT = 1,
        MN_REJECTED = 2,
        MN_NORES = 3,
        MN_SECURITY = 4,
        MN_CLOSED = 5,
        MN_CONNLOST = 1,
        MN_NOCONN = 2,
        MN_THREAD = 1,
        MN_MEMORY = 2,
        MN_OBJECT = 3,
        MN_SEEKGFAIL = 1,
        MN_READFAIL = 2,
        MN_SEEKPFAIL = 3,
        MN_WRITEFAIL = 4,
        MN_ISBOUND = 1,
        MN_ISCONNECTED = 2,
        MN_INVAL = 3,
        MN_SIDINVAL = 4,
        MN_ISUNBOUND = 5,
        MN_NOLISTEN = 6,
        MN_ISRENDEZVOUS = 7,
        MN_ISRENDUNBOUND = 8,
        MN_INVALMSGAPI = 9,
        MN_INVALBUFFERAPI = 10,
        MN_BUSY = 11,
        MN_XSIZE = 12,
        MN_EIDINVAL = 13,
        MN_EEMPTY = 14,
        MN_BUSYPORT = 15,
        MN_WRAVAIL = 1,
        MN_RDAVAIL = 2,
        MN_XMTIMEOUT = 3,
        MN_CONGESTION = 4
    };
    typedef enum SRT_ERRNO
    {
        SRT_EUNKNOWN = -1,
        SRT_SUCCESS = MJ_SUCCESS,
        SRT_ECONNSETUP = (1000 * MJ_SETUP),
        SRT_ENOSERVER = (1000 * MJ_SETUP + MN_TIMEOUT),
        SRT_ECONNREJ = (1000 * MJ_SETUP + MN_REJECTED),
        SRT_ESOCKFAIL = (1000 * MJ_SETUP + MN_NORES),
        SRT_ESECFAIL = (1000 * MJ_SETUP + MN_SECURITY),
        SRT_ESCLOSED = (1000 * MJ_SETUP + MN_CLOSED),
        SRT_ECONNFAIL = (1000 * MJ_CONNECTION),
        SRT_ECONNLOST = (1000 * MJ_CONNECTION + MN_CONNLOST),
        SRT_ENOCONN = (1000 * MJ_CONNECTION + MN_NOCONN),
        SRT_ERESOURCE = (1000 * MJ_SYSTEMRES),
        SRT_ETHREAD = (1000 * MJ_SYSTEMRES + MN_THREAD),
        SRT_ENOBUF = (1000 * MJ_SYSTEMRES + MN_MEMORY),
        SRT_ESYSOBJ = (1000 * MJ_SYSTEMRES + MN_OBJECT),
        SRT_EFILE = (1000 * MJ_FILESYSTEM),
        SRT_EINVRDOFF = (1000 * MJ_FILESYSTEM + MN_SEEKGFAIL),
        SRT_ERDPERM = (1000 * MJ_FILESYSTEM + MN_READFAIL),
        SRT_EINVWROFF = (1000 * MJ_FILESYSTEM + MN_SEEKPFAIL),
        SRT_EWRPERM = (1000 * MJ_FILESYSTEM + MN_WRITEFAIL),
        SRT_EINVOP = (1000 * MJ_NOTSUP),
        SRT_EBOUNDSOCK = (1000 * MJ_NOTSUP + MN_ISBOUND),
        SRT_ECONNSOCK = (1000 * MJ_NOTSUP + MN_ISCONNECTED),
        SRT_EINVPARAM = (1000 * MJ_NOTSUP + MN_INVAL),
        SRT_EINVSOCK = (1000 * MJ_NOTSUP + MN_SIDINVAL),
        SRT_EUNBOUNDSOCK = (1000 * MJ_NOTSUP + MN_ISUNBOUND),
        SRT_ENOLISTEN = (1000 * MJ_NOTSUP + MN_NOLISTEN),
        SRT_ERDVNOSERV = (1000 * MJ_NOTSUP + MN_ISRENDEZVOUS),
        SRT_ERDVUNBOUND = (1000 * MJ_NOTSUP + MN_ISRENDUNBOUND),
        SRT_EINVALMSGAPI = (1000 * MJ_NOTSUP + MN_INVALMSGAPI),
        SRT_EINVALBUFFERAPI = (1000 * MJ_NOTSUP + MN_INVALBUFFERAPI),
        SRT_EDUPLISTEN = (1000 * MJ_NOTSUP + MN_BUSY),
        SRT_ELARGEMSG = (1000 * MJ_NOTSUP + MN_XSIZE),
        SRT_EINVPOLLID = (1000 * MJ_NOTSUP + MN_EIDINVAL),
        SRT_EPOLLEMPTY = (1000 * MJ_NOTSUP + MN_EEMPTY),
        SRT_EBINDCONFLICT = (1000 * MJ_NOTSUP + MN_BUSYPORT),
        SRT_EASYNCFAIL = (1000 * MJ_AGAIN),
        SRT_EASYNCSND = (1000 * MJ_AGAIN + MN_WRAVAIL),
        SRT_EASYNCRCV = (1000 * MJ_AGAIN + MN_RDAVAIL),
        SRT_ETIMEOUT = (1000 * MJ_AGAIN + MN_XMTIMEOUT),
        SRT_ECONGEST = (1000 * MJ_AGAIN + MN_CONGESTION),
        SRT_EPEERERR = (1000 * MJ_PEERERROR)
    } SRT_ERRNO;
    enum SRT_REJECT_REASON
    {
        SRT_REJ_UNKNOWN,
        SRT_REJ_SYSTEM,
        SRT_REJ_PEER,
        SRT_REJ_RESOURCE,
        SRT_REJ_ROGUE,
        SRT_REJ_BACKLOG,
        SRT_REJ_IPE,
        SRT_REJ_CLOSE,
        SRT_REJ_VERSION,
        SRT_REJ_RDVCOOKIE,
        SRT_REJ_BADSECRET,
        SRT_REJ_UNSECURE,
        SRT_REJ_MESSAGEAPI,
        SRT_REJ_CONGESTION,
        SRT_REJ_FILTER,
        SRT_REJ_GROUP,
        SRT_REJ_TIMEOUT,
        SRT_REJ_E_SIZE,
    };
    enum SRT_KM_STATE
    {
        SRT_KM_S_UNSECURED = 0,
        SRT_KM_S_SECURING = 1,
        SRT_KM_S_SECURED = 2,
        SRT_KM_S_NOSECRET = 3,
        SRT_KM_S_BADSECRET = 4
    };
    enum SRT_EPOLL_OPT
    {
       SRT_EPOLL_OPT_NONE = 0x0,
       SRT_EPOLL_IN = 0x1,
       SRT_EPOLL_OUT = 0x4,
       SRT_EPOLL_ERR = 0x8,
       SRT_EPOLL_CONNECT = SRT_EPOLL_OUT,
       SRT_EPOLL_ACCEPT = SRT_EPOLL_IN,
       SRT_EPOLL_UPDATE = 0x10,
       SRT_EPOLL_ET = 1u << 31
    };
    typedef int32_t SRT_EPOLL_T;
    enum SRT_EPOLL_FLAGS
    {
        SRT_EPOLL_ENABLE_EMPTY = 1,
        SRT_EPOLL_ENABLE_OUTPUTCHECK = 2
    };
    typedef struct CBytePerfMon SRT_TRACEBSTATS;
    static const SRTSOCKET SRT_INVALID_SOCK = -1;
    static const int SRT_ERROR = -1;
    int srt_startup(void);
    int srt_cleanup(void);
    SRTSOCKET srt_socket(int, int, int);
    SRTSOCKET srt_create_socket(void);
    int srt_bind (SRTSOCKET u, const struct sockaddr* name, int namelen);
    int srt_bind_acquire (SRTSOCKET u, UDPSOCKET sys_udp_sock);
                          static inline int srt_bind_peerof(SRTSOCKET u, UDPSOCKET sys_udp_sock);
    static inline int srt_bind_peerof (SRTSOCKET u, UDPSOCKET sys_udp_sock) { return srt_bind_acquire(u, sys_udp_sock); }
    int srt_listen (SRTSOCKET u, int backlog);
    SRTSOCKET srt_accept (SRTSOCKET u, struct sockaddr* addr, int* addrlen);
    SRTSOCKET srt_accept_bond (const SRTSOCKET listeners[], int lsize, int64_t msTimeOut);
    typedef int srt_listen_callback_fn (void* opaq, SRTSOCKET ns, int hsversion, const struct sockaddr* peeraddr, const char* streamid);
    int srt_listen_callback(SRTSOCKET lsn, srt_listen_callback_fn* hook_fn, void* hook_opaque);
    typedef void srt_connect_callback_fn (void* opaq, SRTSOCKET ns, int errorcode, const struct sockaddr* peeraddr, int token);
    int srt_connect_callback(SRTSOCKET clr, srt_connect_callback_fn* hook_fn, void* hook_opaque);
    int srt_connect (SRTSOCKET u, const struct sockaddr* name, int namelen);
    int srt_connect_debug(SRTSOCKET u, const struct sockaddr* name, int namelen, int forced_isn);
    int srt_connect_bind (SRTSOCKET u, const struct sockaddr* source,
                                        const struct sockaddr* target, int len);
    int srt_rendezvous (SRTSOCKET u, const struct sockaddr* local_name, int local_namelen,
                                        const struct sockaddr* remote_name, int remote_namelen);
    int srt_close (SRTSOCKET u);
    int srt_getpeername (SRTSOCKET u, struct sockaddr* name, int* namelen);
    int srt_getsockname (SRTSOCKET u, struct sockaddr* name, int* namelen);
    int srt_getsockopt (SRTSOCKET u, int level , SRT_SOCKOPT optname, void* optval, int* optlen);
    int srt_setsockopt (SRTSOCKET u, int level , SRT_SOCKOPT optname, const void* optval, int optlen);
    int srt_getsockflag (SRTSOCKET u, SRT_SOCKOPT opt, void* optval, int* optlen);
    int srt_setsockflag (SRTSOCKET u, SRT_SOCKOPT opt, const void* optval, int optlen);
    typedef struct SRT_SocketGroupData_ SRT_SOCKGROUPDATA;
    typedef struct SRT_MsgCtrl_
    {
       int flags;
       int msgttl;
       int inorder;
       int boundary;
       int64_t srctime;
       int32_t pktseq;
       int32_t msgno;
       SRT_SOCKGROUPDATA* grpdata;
       size_t grpdata_size;
    } SRT_MSGCTRL;
    static const int32_t SRT_SEQNO_NONE = -1;
    static const int32_t SRT_MSGNO_NONE = -1;
    static const int32_t SRT_MSGNO_CONTROL = 0;
    static const int SRT_MSGTTL_INF = -1;
    void srt_msgctrl_init(SRT_MSGCTRL* mctrl);
    extern const SRT_MSGCTRL srt_msgctrl_default;
    int srt_send (SRTSOCKET u, const char* buf, int len);
    int srt_sendmsg (SRTSOCKET u, const char* buf, int len, int ttl , int inorder );
    int srt_sendmsg2(SRTSOCKET u, const char* buf, int len, SRT_MSGCTRL *mctrl);
    int srt_recv (SRTSOCKET u, char* buf, int len);
    int srt_recvmsg (SRTSOCKET u, char* buf, int len);
    int srt_recvmsg2(SRTSOCKET u, char *buf, int len, SRT_MSGCTRL *mctrl);
    int64_t srt_sendfile(SRTSOCKET u, const char* path, int64_t* offset, int64_t size, int block);
    int64_t srt_recvfile(SRTSOCKET u, const char* path, int64_t* offset, int64_t size, int block);
    const char* srt_getlasterror_str(void);
    int srt_getlasterror(int* errno_loc);
    const char* srt_strerror(int code, int errnoval);
    void srt_clearlasterror(void);
    int srt_bstats(SRTSOCKET u, SRT_TRACEBSTATS * perf, int clear);
    int srt_bistats(SRTSOCKET u, SRT_TRACEBSTATS * perf, int clear, int instantaneous);
    SRT_SOCKSTATUS srt_getsockstate(SRTSOCKET u);
    int srt_epoll_create(void);
    int srt_epoll_clear_usocks(int eid);
    int srt_epoll_add_usock(int eid, SRTSOCKET u, const int* events);
    int srt_epoll_add_ssock(int eid, SYSSOCKET s, const int* events);
    int srt_epoll_remove_usock(int eid, SRTSOCKET u);
    int srt_epoll_remove_ssock(int eid, SYSSOCKET s);
    int srt_epoll_update_usock(int eid, SRTSOCKET u, const int* events);
    int srt_epoll_update_ssock(int eid, SYSSOCKET s, const int* events);
    int srt_epoll_wait(int eid, SRTSOCKET* readfds, int* rnum, SRTSOCKET* writefds, int* wnum, int64_t msTimeOut,
                               SYSSOCKET* lrfds, int* lrnum, SYSSOCKET* lwfds, int* lwnum);
    typedef struct SRT_EPOLL_EVENT_STR
    {
        SRTSOCKET fd;
        int events;
    } SRT_EPOLL_EVENT;
    int srt_epoll_uwait(int eid, SRT_EPOLL_EVENT* fdsSet, int fdsSize, int64_t msTimeOut);
    int32_t srt_epoll_set(int eid, int32_t flags);
    int srt_epoll_release(int eid);
    void srt_setloglevel(int ll);
    void srt_addlogfa(int fa);
    void srt_dellogfa(int fa);
    void srt_resetlogfa(const int* fara, size_t fara_size);
    void srt_setloghandler(void* opaque, SRT_LOG_HANDLER_FN* handler);
    void srt_setlogflags(int flags);
    int srt_getsndbuffer(SRTSOCKET sock, size_t* blocks, size_t* bytes);
    int srt_getrejectreason(SRTSOCKET sock);
    int srt_setrejectreason(SRTSOCKET sock, int value);
    extern const char* const srt_rejectreason_msg [];
    const char* srt_rejectreason_str(int id);
    uint32_t srt_getversion(void);
    int64_t srt_time_now(void);
    int64_t srt_connection_time(SRTSOCKET sock);
    int srt_clock_type(void);
    typedef enum SRT_GROUP_TYPE
    {
        SRT_GTYPE_UNDEFINED,
        SRT_GTYPE_BROADCAST,
        SRT_GTYPE_BACKUP,
        SRT_GTYPE_E_END
    } SRT_GROUP_TYPE;
    static const uint32_t SRT_GFLAG_SYNCONMSG = 1;
    typedef enum SRT_MemberStatus
    {
        SRT_GST_PENDING,
        SRT_GST_IDLE,
        SRT_GST_RUNNING,
        SRT_GST_BROKEN
    } SRT_MEMBERSTATUS;
    struct SRT_SocketGroupData_
    {
        SRTSOCKET id;
        struct sockaddr_storage peeraddr;
        SRT_SOCKSTATUS sockstate;
        uint16_t weight;
        SRT_MEMBERSTATUS memberstate;
        int result;
        int token;
    };
    typedef struct SRT_SocketOptionObject SRT_SOCKOPT_CONFIG;
    typedef struct SRT_GroupMemberConfig_
    {
        SRTSOCKET id;
        struct sockaddr_storage srcaddr;
        struct sockaddr_storage peeraddr;
        uint16_t weight;
        SRT_SOCKOPT_CONFIG* config;
        int errorcode;
        int token;
    } SRT_SOCKGROUPCONFIG;
    SRTSOCKET srt_create_group(SRT_GROUP_TYPE);
    SRTSOCKET srt_groupof(SRTSOCKET socket);
    int srt_group_data(SRTSOCKET socketgroup, SRT_SOCKGROUPDATA* output, size_t* inoutlen);
    SRT_SOCKOPT_CONFIG* srt_create_config(void);
    void srt_delete_config(SRT_SOCKOPT_CONFIG* config );
    int srt_config_add(SRT_SOCKOPT_CONFIG* config, SRT_SOCKOPT option, const void* contents, int len);
    SRT_SOCKGROUPCONFIG srt_prepare_endpoint(const struct sockaddr* src , const struct sockaddr* adr, int namelen);
    int srt_connect_group(SRTSOCKET group, SRT_SOCKGROUPCONFIG name[], int arraysize);
]])

return srt

### 查询最大id
MySQL [esports_x_lol_release]> select max(bMatchId) mid from lol_smatch_list_from_bmatch;
+------+
| mid  |
+------+
| 3550 |
+------+
1 row in set (0.12 sec)

MySQL [esports_x_lol_release]> select max(bmatchId) from lol_smatch_list_from_bmatch;
+---------------+
| max(bmatchId) |
+---------------+
|          3550 |
+---------------+

###
apt-get install python-bs4
pip install requests

### 阿里云可能出问题的地方
http://www.qingpingshan.com/pc/fwq/102790.html

### 打印日志
import logging
logging.basicConfig(
    format = "%(asctime)s-%(levelname)s: %(message)s",
    level = logging.DEBUG,
    filename = "run-inserdata.log"
)

函数里面调用

logging.debug("url: %s",url)

### 断点
双击某一处，执行时会在这个地方停，并且可以看到当前每个变量的值。
print 变量
print + ******** 用来确定是不是当前的值.

### 爬虫结构分析 

函数名 | 数据表 | 备注
--- | --- | ----
insert_game_list | lol_sgame_list/lol_bgame_list | gamelist.json
insert_lolmatch_home_page | lol_match2_match_homepage/_bmatch_list | 
insert_Lol_match2_team_list | lol_match2_team_list | lol_match2_team_list
insert_BMatchInfo | lol_bmatch_get_a_vs_b | searchBMatchInfo.php?page= & pagesize= &
insert_SMatchInfo_from_bMatch | lol_smatch_list_from_bmatch | searchSMatchList.php
insert_searchMatchInfo_s | lol_smatch_info_s/lol_smatch_info_s_smatch_member/lol_smatch_info_s_battle_info | SELECT sMatchId from  lol_smatch_list_from_bmatch//lol/match/apis/searchMatchInfo_s.php?
insert_query_battle_info_by_battle_id| lol_smatch_battle_info | select from lol_smatch_info_s/lol/livedata/?p0=1&p1=searchData&req_type=query_battle_info_by_battle_id
query_team_battle_event | lol_smatch_team_battle_event | select from lol_smatch_battle_info_room/lol/livedata/?p0=1&p1=searchData&req_type=query_team_battle_event
query_eye_pos | lol_smatch_battle_eye_pos |select from lol_smatch_battle_info_room /lol/livedata/?p0=1&p1=searchData&req_type=query_eye_pos&source=vod
query_dragon_event|lol_smatch_battle_dragon_event | lol_smatch_battle_info_room/lol/livedata/?p0=1&p1=searchData&req_type=query_dragon_event
query_kill_pos |lol_smatch_battle_pos_kill /lol_smatch_battle_pos_dead| lol_smatch_battle_info_room/lol/livedata/?p0=1&p1=searchData&req_type=query_kill_pos
insertLOL_MATCH2_GAME_GAME_INFO | lol_match2_game_game_baseinfo| lpl.qq.com/web201612/data/LOL_MATCH2_GAME_GAME


### 创建数据库
drop database esport_x_lol_release;
CREATE DATABASE `esports_x_lol_release` /*!40100 DEFAULT CHARACTER SET utf8 */

mysqldump esports_x_lol_dev -uroot -p --add-drop-table | mysql esports_x_lol_release -uroot -p

class_name CardPool
extends RefCounted

const CARDS: Array[String] = [
	"res://data/cards/strike.tres",
	"res://data/cards/defend.tres",
	"res://data/cards/bash.tres",
	"res://data/cards/slash.tres",
	"res://data/cards/insight.tres",
	"res://data/cards/quick_strike.tres",
	"res://data/cards/energize.tres",
	"res://data/cards/dash.tres",
	"res://data/cards/entangle.tres",
]

const RELICS: Array[String] = [
	"res://data/relics/burning_gem.tres",
	"res://data/relics/can_xiu_hun_jing.tres",
	"res://data/relics/tian_di_lie_hen.tres",
	"res://data/relics/shuo_zhi_hui_yin.tres",
	"res://data/relics/dan_xin_jing.tres",
	"res://data/relics/wu_ming_hu_fu.tres",
	"res://data/relics/sui_jing_pian.tres",
	"res://data/relics/bu_san_zhi_nian.tres",
	"res://data/relics/jie_huo_he_xin.tres",
	"res://data/relics/ling_gen_can_zhi.tres",
	"res://data/relics/tong_xin_suo.tres",
	"res://data/relics/jiu_ri_bi_ji.tres",
	"res://data/relics/xu_kong_ping.tres",
	"res://data/relics/wu_xu_xiang_lu.tres",
	"res://data/relics/fang_shi_zhang_bu.tres",
	"res://data/relics/si_xian_mu_jie.tres",
	"res://data/relics/lun_hui_guan_jing.tres",
	"res://data/relics/hun_si_chan_rao.tres",
	"res://data/relics/gui_xu_zhi_gu.tres",
	"res://data/relics/ling_shi_chong.tres",
	"res://data/relics/wu_ming_zhi_gu.tres",
]

const CHEST_RELICS: Array[String] = [
	"res://data/relics/iron_armor.tres",
	"res://data/relics/tome_of_wisdom.tres",
]

const SWORD_START_RELICS: Array[String] = [
	"res://data/relics/sword_gourd.tres",
]

const SWORD_REWARD_CARDS: Array[String] = [
	"res://data/cards/bash.tres",
	"res://data/cards/entangle.tres",
	"res://data/cards/zhan_tie.tres",
	"res://data/cards/po_feng.tres",
	"res://data/cards/ce_bu.tres",
	"res://data/cards/lian_xi.tres",
	"res://data/cards/chuan_xin.tres",
	"res://data/cards/yang_jian_shu.tres",
	"res://data/cards/lue_ying.tres",
	"res://data/cards/sui_xing.tres",
	"res://data/cards/heng_jian.tres",
	"res://data/cards/lie_kong.tres",
	"res://data/cards/wu_hen.tres",
	"res://data/cards/po_jun.tres",
	"res://data/cards/wan_jian_gui_zong.tres",
	"res://data/cards/jian_yu.tres",
	"res://data/cards/xin_jian.tres",
	"res://data/cards/jian_qiao.tres",
	"res://data/cards/jian_qi_ying_ti.tres",
	"res://data/cards/jing_hong.tres",
	"res://data/cards/jian_bu.tres",
	"res://data/cards/ren_jian_he_yi.tres",
	"res://data/cards/yi_sui_xin_fa.tres",
]

const GRADE_1_CARDS: Array[String] = [
	"res://data/cards/bash.tres",
	"res://data/cards/entangle.tres",
	"res://data/cards/zhan_tie.tres",
	"res://data/cards/po_feng.tres",
	"res://data/cards/ce_bu.tres",
	"res://data/cards/lian_xi.tres",
	"res://data/cards/chuan_xin.tres",
	"res://data/cards/yang_jian_shu.tres",
	"res://data/cards/lue_ying.tres",
	"res://data/cards/sui_xing.tres",
	"res://data/cards/heng_jian.tres",
	"res://data/cards/lie_kong.tres",
	"res://data/cards/wu_hen.tres",
	"res://data/cards/jian_bu.tres",
	"res://data/cards/jian_qiao.tres",
	"res://data/cards/jian_qi_ying_ti.tres",
]

const GRADE_2_CARDS: Array[String] = [
	"res://data/cards/po_jun.tres",
	"res://data/cards/wan_jian_gui_zong.tres",
	"res://data/cards/jian_yu.tres",
	"res://data/cards/xin_jian.tres",
	"res://data/cards/jing_hong.tres",
	"res://data/cards/ren_jian_he_yi.tres",
	"res://data/cards/yi_sui_xin_fa.tres",
]

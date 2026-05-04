extends Node

signal language_changed(language_code: String)

const LANGUAGE_RU := "ru"
const LANGUAGE_EN := "en"
const LANGUAGE_ZH_CN := "zh_CN"
const SETTINGS_PATH := "user://settings.cfg"

var language_code: String = LANGUAGE_RU

var _texts := {
	LANGUAGE_RU: {
		"language.ru": "Русский",
		"language.en": "Английский",
		"language.zh_cn": "Упрощенный китайский",
		"main.new_game": "Новая игра",
		"main.continue": "Продолжить",
		"main.settings": "Настройки",
		"main.exit": "Выход",
		"main.subtitle": "Приключения ждут тебя!",
		"settings.title": "Настройки",
		"settings.resolution": "Разрешение экрана",
		"settings.language": "Язык",
		"settings.apply": "Принять изменения",
		"settings.cancel": "Выйти без изменений",
		"save.new_game": "Новая игра",
		"save.continue": "Продолжить",
		"save.back": "Назад",
		"save.slot": "Слот %d",
		"save.unnamed": "Без имени",
		"save.occupied": "Занят: %s",
		"save.empty_slot": "Пустой слот",
		"save.enter_pilot": "Введите имя пилота",
		"save.confirm": "Подтвердить",
		"save.load": "Загрузить",
		"save.found": "Сохранение найдено",
		"save.unknown": "Неизвестно",
		"save.pilot": "Пилот: %s",
		"save.location": "Локация: %s",
		"save.completed_quests": "Квестов пройдено: %d",
		"save.play_time": "Время в игре: %s",
		"ship.quest": "Квест",
		"ship.continue_quest": "Продолжить квест",
		"ship.next_adventure": "Новое приключение!",
		"ship.menu": "В меню",
		"ship.cargo_bay": "Грузовой отсек",
		"ship.confirmation": "Подтверждение",
		"ship.accept": "Принять",
		"ship.reject": "Отклонить",
		"ship.jump_confirm_completed": "Совершить прыжок в другую локацию?",
		"ship.jump_confirm_unfinished": "Здесь еще есть кое-что интересное! Оставить локацию и лететь дальше?",
		"cargo.equipment": "Снаряжение",
		"cargo.interior": "Интерьер",
		"cargo.hardware": "Оборудование",
		"cargo.pets": "Питомцы",
		"cargo.close": "Закрыть",
		"cargo.use": "Использовать",
		"cargo.equipped": "Используется",
		"cargo.install": "Установить",
		"cargo.remove": "Убрать",
		"cargo.installed_zone": "Установлен в зоне %d.",
		"cargo.not_installed": "Не установлен.",
		"cargo.unknown_item": "Неизвестный предмет",
		"cargo.unknown_module": "Неизвестный модуль",
		"cargo.unknown_pet": "Неизвестный питомец",
		"cargo.no_description": "Описание отсутствует.",
		"cargo.interior_item_title": "Растение № %d",
		"cargo.interior_item_description": "Заглушка описания. Интерьерный предмет для кокпита, вариант %d.",
		"cargo.sleep_zone": "Спальная зона",
		"cargo.workzone": "Рабочая зона",
		"cargo.front_zone": "Зона отдыха",
		"cargo.front_panel": "Передняя панель",
		"cargo.module_title": "%s, модуль %d",
		"cargo.module_description": "Тестовое описание. %s, модуль %d.",
		"cargo.panel_description": "Заменяет верхнюю переднюю панель кокпита на вариант %d.",
		"pet.summon": "Призвать",
		"pet.return": "Вернуть",
		"quest.default_title": "Текстовый квест",
		"quest.finish": "Завершить",
		"quest.next": "Далее",
		"quest.close": "Закрыть",
	},
	LANGUAGE_EN: {
		"language.ru": "Russian",
		"language.en": "English",
		"language.zh_cn": "Simplified Chinese",
		"main.new_game": "New Game",
		"main.continue": "Continue",
		"main.settings": "Settings",
		"main.exit": "Exit",
		"main.subtitle": "Adventure awaits!",
		"settings.title": "Settings",
		"settings.resolution": "Screen Resolution",
		"settings.language": "Language",
		"settings.apply": "Apply Changes",
		"settings.cancel": "Exit Without Changes",
		"save.new_game": "New Game",
		"save.continue": "Continue",
		"save.back": "Back",
		"save.slot": "Slot %d",
		"save.unnamed": "Unnamed",
		"save.occupied": "Occupied: %s",
		"save.empty_slot": "Empty slot",
		"save.enter_pilot": "Enter pilot name",
		"save.confirm": "Confirm",
		"save.load": "Load",
		"save.found": "Save found",
		"save.unknown": "Unknown",
		"save.pilot": "Pilot: %s",
		"save.location": "Location: %s",
		"save.completed_quests": "Completed quests: %d",
		"save.play_time": "Play time: %s",
		"ship.quest": "Quest",
		"ship.continue_quest": "Continue Quest",
		"ship.next_adventure": "New Adventure!",
		"ship.menu": "To Menu",
		"ship.cargo_bay": "Cargo Bay",
		"ship.confirmation": "Confirmation",
		"ship.accept": "Accept",
		"ship.reject": "Decline",
		"ship.jump_confirm_completed": "Make the jump to another location?",
		"ship.jump_confirm_unfinished": "There is still something interesting here! Leave this location and fly onward?",
		"cargo.equipment": "Equipment",
		"cargo.interior": "Interior",
		"cargo.hardware": "Hardware",
		"cargo.pets": "Pets",
		"cargo.close": "Close",
		"cargo.use": "Use",
		"cargo.equipped": "Equipped",
		"cargo.install": "Install",
		"cargo.remove": "Remove",
		"cargo.installed_zone": "Installed in zone %d.",
		"cargo.not_installed": "Not installed.",
		"cargo.unknown_item": "Unknown item",
		"cargo.unknown_module": "Unknown module",
		"cargo.unknown_pet": "Unknown pet",
		"cargo.no_description": "No description available.",
		"cargo.interior_item_title": "Plant No. %d",
		"cargo.interior_item_description": "Placeholder description. Interior cockpit item, variant %d.",
		"cargo.sleep_zone": "Sleeping Area",
		"cargo.workzone": "Work Area",
		"cargo.front_zone": "Lounge Area",
		"cargo.front_panel": "Front Panel",
		"cargo.module_title": "%s, module %d",
		"cargo.module_description": "Test description. %s, module %d.",
		"cargo.panel_description": "Replaces the upper cockpit front panel with variant %d.",
		"pet.summon": "Summon",
		"pet.return": "Return",
		"quest.default_title": "Text Quest",
		"quest.finish": "Finish",
		"quest.next": "Next",
		"quest.close": "Close",
	},
	LANGUAGE_ZH_CN: {
		"language.ru": "俄语",
		"language.en": "英语",
		"language.zh_cn": "简体中文",
		"main.new_game": "新游戏",
		"main.continue": "继续",
		"main.settings": "设置",
		"main.exit": "退出",
		"main.subtitle": "冒险正在等待你！",
		"settings.title": "设置",
		"settings.resolution": "屏幕分辨率",
		"settings.language": "语言",
		"settings.apply": "应用更改",
		"settings.cancel": "不保存退出",
		"save.new_game": "新游戏",
		"save.continue": "继续",
		"save.back": "返回",
		"save.slot": "存档槽 %d",
		"save.unnamed": "未命名",
		"save.occupied": "已占用：%s",
		"save.empty_slot": "空存档槽",
		"save.enter_pilot": "输入驾驶员姓名",
		"save.confirm": "确认",
		"save.load": "加载",
		"save.found": "发现存档",
		"save.unknown": "未知",
		"save.pilot": "驾驶员：%s",
		"save.location": "位置：%s",
		"save.completed_quests": "已完成任务：%d",
		"save.play_time": "游戏时间：%s",
		"ship.quest": "任务",
		"ship.continue_quest": "继续任务",
		"ship.next_adventure": "新的冒险！",
		"ship.menu": "返回菜单",
		"ship.cargo_bay": "货舱",
		"ship.confirmation": "确认",
		"ship.accept": "接受",
		"ship.reject": "拒绝",
		"ship.jump_confirm_completed": "跃迁到另一个地点？",
		"ship.jump_confirm_unfinished": "这里还有一些有趣的东西！要离开此地点继续飞行吗？",
		"cargo.equipment": "装备",
		"cargo.interior": "内饰",
		"cargo.hardware": "硬件",
		"cargo.pets": "宠物",
		"cargo.close": "关闭",
		"cargo.use": "使用",
		"cargo.equipped": "已装备",
		"cargo.install": "安装",
		"cargo.remove": "移除",
		"cargo.installed_zone": "已安装在区域 %d。",
		"cargo.not_installed": "未安装。",
		"cargo.unknown_item": "未知物品",
		"cargo.unknown_module": "未知模块",
		"cargo.unknown_pet": "未知宠物",
		"cargo.no_description": "暂无描述。",
		"cargo.interior_item_title": "植物 %d",
		"cargo.interior_item_description": "占位描述。驾驶舱内饰物品，型号 %d。",
		"cargo.sleep_zone": "睡眠区",
		"cargo.workzone": "工作区",
		"cargo.front_zone": "休息区",
		"cargo.front_panel": "前面板",
		"cargo.module_title": "%s，模块 %d",
		"cargo.module_description": "测试描述。%s，模块 %d。",
		"cargo.panel_description": "将驾驶舱上方前面板替换为型号 %d。",
		"pet.summon": "召唤",
		"pet.return": "返回",
		"quest.default_title": "文字任务",
		"quest.finish": "完成",
		"quest.next": "下一步",
		"quest.close": "关闭",
	},
}

var _item_texts_en := {
	"standard_suit": {
		"title": "Standard Spacesuit",
		"description": "A basic shipboard spacesuit for calm, long expeditions."
	},
	"heavy_rescue_suit": {
		"title": "Heavy Rescue Suit",
		"description": "A reinforced emergency rescue suit for debris fields, depressurized stations, and hazardous technical zones."
	},
	"nova_suit": {
		"title": "Experimental Nova Suit",
		"description": "A one-of-a-kind suit made of nanite fabric, closer to a technological artifact than standard equipment."
	},
	"ar_visor": {
		"title": "Augmented Reality Visor",
		"description": "Advanced under-helmet glasses that overlay the world with an extra layer of useful information."
	},
	"wave_drone": {
		"title": "Wave Levitation Drone",
		"description": "A compact semi-autonomous ball-sized drone capable of moving through vacuum, gas, and liquid."
	},
	"analytic_resonator": {
		"title": "Analytical Resonator",
		"description": "A forearm and wrist complex resembling a mini-computer with a set of sensors and universal interfaces."
	},
	"smart_metal_container": {
		"title": "Smart Metal Belt",
		"description": "Alien technology adapted for humans: a container with a metal-like substance that changes shape on operator command."
	},
	"plasma_cutter": {
		"title": "Plasma Cutter",
		"description": "A handheld tool that emits a controlled plasma beam from a few centimeters up to a meter long."
	},
	"strange_cube": {
		"title": "Strange Cube",
		"description": "A mysterious pulsing cube found on an abandoned station far from normal routes."
	},
}

var _item_texts_zh_cn := {
	"standard_suit": {
		"title": "标准宇航服",
		"description": "基础舰载宇航服，适合平稳而漫长的远征。"
	},
	"heavy_rescue_suit": {
		"title": "重型救援服",
		"description": "强化应急救援宇航服，适用于废墟、失压空间站和危险技术区域。"
	},
	"nova_suit": {
		"title": "“新星”实验服",
		"description": "独一无二的纳米织物宇航服，与其说是量产装备，不如说更像一件科技遗物。"
	},
	"ar_visor": {
		"title": "增强现实面罩",
		"description": "可佩戴在头盔内的高级眼镜，能在现实世界上叠加一层有用信息。"
	},
	"wave_drone": {
		"title": "波动悬浮无人机",
		"description": "一台球形大小的半自主紧凑无人机，能在真空、气体和液体中移动。"
	},
	"analytic_resonator": {
		"title": "分析谐振器",
		"description": "安装在前臂和手腕上的综合设备，类似带有传感器和通用接口的微型计算机。"
	},
	"smart_metal_container": {
		"title": "智能金属腰带",
		"description": "为人类改造的外星技术：容器内的类金属物质可按操作者指令改变形态。"
	},
	"plasma_cutter": {
		"title": "等离子切割器",
		"description": "手持工具，可释放长度从数厘米到一米不等的可控等离子束。"
	},
	"strange_cube": {
		"title": "奇异立方体",
		"description": "在远离常规航线的废弃空间站中发现的神秘脉动立方体。"
	},
}

var _pet_texts := {
	LANGUAGE_RU: {
		"alien_jelly": {
			"name": "Левитирующая медузка",
			"description": "Мягко светящееся существо, способное бесшумно дрейфовать по кабине часами.",
			"history": "Найдена в старом биоконтейнере среди груза, который давно должен был быть списан. Похоже, медузка решила, что корабль теперь ее дом."
		},
		"marta_cat": {
			"name": "Марта",
			"description": "Рыжая кошка с независимым характером и удивительным талантом устраиваться в самых неожиданных местах.",
			"history": "Найдена в гибернационной камере дрейфующего модуля и спасена игроком. С тех пор считает корабль своей территорией, а экипаж - персоналом."
		},
		"robo_crab": {
			"name": "Мистер Крабс",
			"description": "Экспериментальный сервисный дрон с повышенным интеллектом и чувством собственного величия.",
			"history": "Найден на заброшенной станции и благополучно доставлен на борт вместе со своей станцией."
		},
	},
	LANGUAGE_EN: {
		"alien_jelly": {
			"name": "Levitating Jellyfish",
			"description": "A softly glowing creature that can drift silently around the cabin for hours.",
			"history": "Found in an old biocontainer among cargo that should have been written off long ago. Apparently, the jellyfish decided the ship is its home now."
		},
		"marta_cat": {
			"name": "Marta",
			"description": "A ginger cat with an independent streak and an astonishing talent for settling in the most unexpected places.",
			"history": "Found in a hibernation chamber aboard a drifting module and rescued by the player. Since then, she has considered the ship her territory and the crew her staff."
		},
		"robo_crab": {
			"name": "Mr. Krabs",
			"description": "An experimental service drone with enhanced intelligence and an inflated sense of dignity.",
			"history": "Found on an abandoned station and safely brought aboard together with his station."
		},
	},
	LANGUAGE_ZH_CN: {
		"alien_jelly": {
			"name": "悬浮水母",
			"description": "一种柔和发光的生物，能够在舱室中无声漂浮数小时。",
			"history": "它是在一只旧生物容器中被发现的，那批货物早该报废了。看起来，这只水母已经决定把飞船当成自己的家。"
		},
		"marta_cat": {
			"name": "玛尔塔",
			"description": "一只姜黄色的猫，性格独立，并且总能在最意想不到的地方安顿下来。",
			"history": "她在一座漂流模块的休眠舱中被发现并由玩家救出。从那以后，她认为飞船是自己的领地，而船员只是工作人员。"
		},
		"robo_crab": {
			"name": "克拉布斯先生",
			"description": "一台实验性服务无人机，拥有增强智能和强烈的自尊心。",
			"history": "它在一座废弃空间站上被发现，并连同自己的空间站一起被安全带回船上。"
		},
	},
}


func _ready() -> void:
	load_settings()


func set_language(new_language_code: String) -> void:
	if not _texts.has(new_language_code):
		new_language_code = LANGUAGE_RU
	if language_code == new_language_code:
		return

	language_code = new_language_code
	TranslationServer.set_locale(language_code)
	save_settings()
	language_changed.emit(language_code)


func get_language() -> String:
	return language_code


func tr_text(key: String) -> String:
	var language_texts: Dictionary = _texts.get(language_code, {})
	if language_texts.has(key):
		return language_texts[key]
	return _texts[LANGUAGE_RU].get(key, key)


func format_text(key: String, values: Array = []) -> String:
	return tr_text(key) % values


func get_item_title(item_data) -> String:
	if item_data == null:
		return ""
	if language_code == LANGUAGE_EN and _item_texts_en.has(item_data.item_id):
		return _item_texts_en[item_data.item_id]["title"]
	if language_code == LANGUAGE_ZH_CN and _item_texts_zh_cn.has(item_data.item_id):
		return _item_texts_zh_cn[item_data.item_id]["title"]
	return item_data.title


func get_item_description(item_data) -> String:
	if item_data == null:
		return ""
	if language_code == LANGUAGE_EN and _item_texts_en.has(item_data.item_id):
		return _item_texts_en[item_data.item_id]["description"]
	if language_code == LANGUAGE_ZH_CN and _item_texts_zh_cn.has(item_data.item_id):
		return _item_texts_zh_cn[item_data.item_id]["description"]
	return item_data.description


func get_pet_text(pet_id: String, field: String) -> String:
	var language_pets: Dictionary = _pet_texts.get(language_code, {})
	if language_pets.has(pet_id):
		return String(language_pets[pet_id].get(field, ""))
	var ru_pets: Dictionary = _pet_texts[LANGUAGE_RU]
	var ru_pet: Dictionary = ru_pets.get(pet_id, {})
	return String(ru_pet.get(field, ""))


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		language_code = LANGUAGE_RU
		TranslationServer.set_locale(language_code)
		return

	var saved_language := String(config.get_value("game", "language", LANGUAGE_RU))
	language_code = saved_language if _texts.has(saved_language) else LANGUAGE_RU
	TranslationServer.set_locale(language_code)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "language", language_code)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Localization: failed to save language settings.")

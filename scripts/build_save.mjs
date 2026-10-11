// scripts/build_save.mjs
// 构建《星轨交错：地脉争锋》全量 UI 控件树与工程存档 starlink.save.json

import fs from 'node:fs';
import path from 'node:path';
import { createStudio } from '/mnt/d/Agent/miliastra-beyond-simulator/studio/index.js';
import { createNode } from '/mnt/d/Agent/miliastra-beyond-simulator/studio/ui/authoring.js';
import { createRectTransform } from '/mnt/d/Agent/miliastra-beyond-simulator/studio/ui/layout.js';
import { PLATFORMS } from '/mnt/d/Agent/miliastra-beyond-simulator/studio/constants.js';

function makeTransform({ layout = 'center', anchor = null, offset = [0, 0], size = [100, 40], pivot = [0.5, 0.5], rotationZ = 0 }) {
  const rt = createRectTransform({ layout, size, offset });
  if (anchor) {
    rt.anchorMin = { x: anchor[0], y: anchor[1] };
    rt.anchorMax = { x: anchor[0], y: anchor[1] };
  }
  rt.pivot = { x: pivot[0], y: pivot[1] };
  if (rotationZ) {
    rt.rotation = { x: 0, y: 0, z: rotationZ };
  }
  const out = {};
  for (const p of PLATFORMS) {
    out[p] = JSON.parse(JSON.stringify(rt));
  }
  return out;
}

// 颜色转换助手 (支持 ARGB 16 进制与自定义 Alpha 混合)
function parseColor(str, alpha = 1.0) {
  if (typeof str === 'number') return str >>> 0;
  if (str.startsWith('#')) {
    const hex = str.slice(1);
    if (hex.length === 6) {
      const a = Math.round(alpha * 255);
      return (((a << 24) | parseInt(hex, 16)) >>> 0);
    }
    if (hex.length === 8) {
      return parseInt(hex, 16) >>> 0;
    }
  }
  return 0xffffffff;
}

// 5 节点拓扑
const NODES_DEF = [
  { id: 0, name: '西风枢纽', x: 320, y: 450, r: 54, faction: 'player', parts: 25, ctrl: 100, anom: 'NORMAL' },
  { id: 1, name: '石珀晶矿', x: 650, y: 280, r: 46, faction: 'neutral', parts: 10, ctrl: 0, anom: 'AMBER_MINE' },
  { id: 2, name: '千风隘口', x: 800, y: 520, r: 48, faction: 'neutral', parts: 15, ctrl: 0, anom: 'WIND_FLOW' },
  { id: 3, name: '迷雾荒墟', x: 950, y: 300, r: 44, faction: 'neutral', parts: 8, ctrl: 0, anom: 'MIST_RUINS' },
  { id: 4, name: '愚人坚垒', x: 1280, y: 450, r: 54, faction: 'enemy', parts: 25, ctrl: 100, anom: 'NORMAL' },
];

const LINKS_DEF = [
  [0, 1], [0, 2], [1, 2], [1, 3], [2, 3], [2, 4], [3, 4]
];

// 6 备选战术卡 (对齐 CardRegistry 17种战术符印体系)
const POOL_CARDS = [
  { id: 1, key: 'anemo_shield', name: '千风庇护', cost: 2, desc: '加持免伤结界' },
  { id: 2, key: 'anemo_turb', name: '千风湍流', cost: 3, desc: '流道速度翻倍' },
  { id: 3, key: 'pyro_blast', name: '轰轰烈焰', cost: 4, desc: '消灭80%敌军' },
  { id: 4, key: 'hydro_bribe', name: '摩拉律法', cost: 5, desc: '秒占中立灵穴' },
  { id: 5, key: 'geo_wall', name: '坚岩重嶂', cost: 4, desc: '战损减半反震' },
  { id: 6, key: 'pyro_erosion', name: '烈焰侵蚀', cost: 2, desc: '削减40%微粒' },
];

// ==========================================
// 千星奇域渲染规则：同级节点按照 FRONT-TO-BACK (从前往后) 绘制
// 第 0 个子节点处于最顶层 (Front / On Top)
// 最后一个子节点处于最底层 (Back / Underneath)
// ==========================================

// 安全创建文本框 (保证 minimumFontSize <= fontSize，关闭模糊描边与背景冲突)
function createTextbox(opts) {
  return createNode('textbox', {
    ...opts,
    minimumFontSize: opts.minimumFontSize ?? Math.min(opts.fontSize || 12, 10),
    enableOutline: false,
    bgColor: 0
  });
}

// 1. 终局结算弹窗 SettleModal (最顶层)
const settleModal = createNode('container', {
  id: 'settle_modal',
  name: 'SettleModal',
  visible: false,
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
    // 弹窗对话框实体
    createNode('container', {
      id: 'settle_box',
      name: 'SettleBox',
      transformByPlatform: makeTransform({
        offset: [0, 0],
        size: [640, 380],
        pivot: [0.5, 0.5]
      }),
      children: [
        createNode('button', {
          id: 'settle_retry_btn',
          name: 'SettleRetryBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [0, -115],
            size: [170, 44],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'settle_retry_txt',
              name: 'Text',
              text: '【重新演练】',
              fontSize: 15,
              fontColor: parseColor('#f8fafc'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 0], size: [170, 44], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'settle_retry_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#0284c7'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),
        createTextbox({
          id: 'settle_stats',
          name: 'SettleStats',
          text: '占领灵穴：5/5  |  存活兵力：84  |  耗时：02:45',
          fontSize: 14,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, -30],
            size: [520, 36],
            pivot: [0.5, 0.5]
          })
        }),
        createTextbox({
          id: 'settle_desc',
          name: 'SettleDesc',
          text: '星盘之理尽在掌控，地脉灵流归于统御。',
          fontSize: 14,
          fontColor: parseColor('#e2e8f0'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, 50],
            size: [520, 50],
            pivot: [0.5, 0.5]
          })
        }),
        createTextbox({
          id: 'settle_title',
          name: 'SettleTitle',
          text: '【推衍大捷·全域共鸣】',
          fontSize: 22,
          fontColor: parseColor('#38bdf8'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, 120],
            size: [500, 44],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'settle_inner_bg',
          name: 'SettleInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({
            offset: [0, 0],
            size: [634, 374],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'settle_border',
          name: 'SettleBorder',
          imageId: 100001,
          imageColor: parseColor('#38bdf8'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    // 半透明背景遮罩
    createNode('image', {
      id: 'settle_mask',
      name: 'SettleMask',
      imageId: 100001,
      imageColor: parseColor('#000000', 0.75),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

// 2. 战前调配弹窗 PrepareModal
const prepCardNodes = POOL_CARDS.map((card, idx) => {
  const col = idx % 3;
  const row = Math.floor(idx / 3);
  const posX = -220 + col * 220;
  const posY = 35 - row * 110;

  return createNode('button', {
    id: `prep_card_${card.id}`,
    name: `PrepCard_${card.id}`,
    raycastTarget: true,
    interactable: true,
    transformByPlatform: makeTransform({
      offset: [posX, posY],
      size: [200, 96],
      pivot: [0.5, 0.5]
    }),
    children: [
      createTextbox({
        id: `prep_check_${card.id}`,
        name: 'CheckTag',
        text: idx < 3 ? '【✓ 已装配】' : '【点击装配】',
        fontSize: 11,
        fontColor: parseColor(idx < 3 ? '#fbbf24' : '#64748b'),
        horizontalAlignment: 'Right',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [45, 24],
          size: [90, 24],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `prep_cost_${card.id}`,
        name: 'CostText',
        text: `消耗: ${card.cost} 权能`,
        fontSize: 12,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, -28],
          size: [180, 24],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `prep_desc_${card.id}`,
        name: 'DescText',
        text: card.desc,
        fontSize: 11,
        fontColor: parseColor('#94a3b8'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, -4],
          size: [180, 28],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `prep_name_${card.id}`,
        name: 'NameText',
        text: card.name,
        fontSize: 14,
        fontColor: parseColor(idx < 3 ? '#f8fafc' : '#94a3b8'),
        horizontalAlignment: 'Left',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [-30, 24],
          size: [110, 28],
          pivot: [0.5, 0.5]
        })
      }),
      createNode('image', {
        id: `prep_cbg_${card.id}`,
        name: 'CardBg',
        imageId: 100001,
        imageColor: parseColor(idx < 3 ? '#1e3a5f' : '#0f172a'),
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [194, 90],
          pivot: [0.5, 0.5]
        })
      }),
      createNode('image', {
        id: `prep_cbdr_${card.id}`,
        name: 'CardBorder',
        imageId: 100001,
        imageColor: parseColor(idx < 3 ? '#fbbf24' : '#475569'),
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [200, 96],
          pivot: [0.5, 0.5]
        })
      })
    ]
  });
});

const prepareModal = createNode('container', {
  id: 'prepare_modal',
  name: 'PrepareModal',
  visible: false,
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
    createNode('container', {
      id: 'prep_box',
      name: 'PrepBox',
      transformByPlatform: makeTransform({
        offset: [0, 0],
        size: [760, 460],
        pivot: [0.5, 0.5]
      }),
      children: [
        createNode('button', {
          id: 'prep_start_btn',
          name: 'PrepStartBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [0, -165],
            size: [220, 46],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'prep_start_txt',
              name: 'Text',
              text: '【开启地脉推衍】',
              fontSize: 16,
              fontColor: parseColor('#f8fafc'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({
                offset: [0, 0],
                size: [220, 46],
                pivot: [0.5, 0.5]
              })
            }),
            createNode('image', {
              id: 'prep_start_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#0284c7'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),
        ...prepCardNodes,
        createTextbox({
          id: 'prep_hint',
          name: 'PrepHint',
          text: '已预装核心卡组：千风庇护(2点) + 千风湍流(3点) + 轰轰烈焰(4点)',
          fontSize: 13,
          fontColor: parseColor('#94a3b8'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, 95],
            size: [600, 28],
            pivot: [0.5, 0.5]
          })
        }),
        createTextbox({
          id: 'prep_budget_txt',
          name: 'PrepBudgetText',
          text: '当前调配权能预算：9 / 12 点',
          fontSize: 15,
          fontColor: parseColor('#38bdf8'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, 130],
            size: [400, 32],
            pivot: [0.5, 0.5]
          })
        }),
        createTextbox({
          id: 'prep_title',
          name: 'PrepTitle',
          text: '【战前符印调配】',
          fontSize: 20,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, 175],
            size: [400, 40],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'prep_inner_bg',
          name: 'PrepInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({
            offset: [0, 0],
            size: [754, 454],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'prep_border',
          name: 'PrepBorder',
          imageId: 100001,
          imageColor: parseColor('#fbbf24'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    createNode('image', {
      id: 'prep_mask',
      name: 'PrepMask',
      imageId: 100001,
      imageColor: parseColor('#000000', 0.70),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

// 3. 剧情弹窗 DialogueModal (开局处于激活呈现状态)
const dialogueModal = createNode('container', {
  id: 'dialogue_modal',
  name: 'DialogueModal',
  visible: true,
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
    createNode('container', {
      id: 'dlg_box',
      name: 'DlgBox',
      transformByPlatform: makeTransform({
        offset: [0, -240],
        size: [880, 170],
        pivot: [0.5, 0.5]
      }),
      children: [
        createNode('button', {
          id: 'dlg_skip_btn',
          name: 'DlgSkipBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [360, 48],
            size: [88, 34],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'dlg_skip_txt',
              name: 'Text',
              text: '【跳过】',
              fontSize: 13,
              fontColor: parseColor('#94a3b8'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({
                offset: [0, 0],
                size: [88, 34],
                pivot: [0.5, 0.5]
              })
            }),
            createNode('image', {
              id: 'dlg_skip_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#1e293b'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),
        createNode('button', {
          id: 'dlg_next_btn',
          name: 'DlgNextBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [360, -48],
            size: [88, 34],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'dlg_next_txt',
              name: 'Text',
              text: '【继续】',
              fontSize: 13,
              fontColor: parseColor('#38bdf8'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({
                offset: [0, 0],
                size: [88, 34],
                pivot: [0.5, 0.5]
              })
            }),
            createNode('image', {
              id: 'dlg_next_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#1e293b'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),
        createTextbox({
          id: 'dlg_content',
          name: 'DlgContent',
          text: '哇！阿贝多，这个泛着蓝光的大圆盘是什么呀？\\n上面亮晶晶的小圆点，看起来好像……会发光的甜甜花糖豆！',
          fontSize: 15,
          fontColor: parseColor('#f8fafc'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Top',
          transformByPlatform: makeTransform({
            offset: [0, -6],
            size: [820, 72],
            pivot: [0.5, 0.5]
          })
        }),
        createTextbox({
          id: 'dlg_speaker',
          name: 'DlgSpeaker',
          text: '【派蒙】',
          fontSize: 18,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [-300, 48],
            size: [220, 36],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'dlg_inner_bg',
          name: 'DlgInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({
            offset: [0, 0],
            size: [874, 164],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'dlg_border',
          name: 'DlgBorder',
          imageId: 100001,
          imageColor: parseColor('#38bdf8'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    createNode('image', {
      id: 'dlg_mask',
      name: 'DlgMask',
      imageId: 100001,
      imageColor: parseColor('#000000', 0.60),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

// 4. 顶部 HUD 与底部符印栏 HudLayer
const cardSlots = [1, 2, 3, 4].map(idx => {
  const offsetX = -210 + (idx - 1) * 140;
  return createNode('container', {
    id: `card_slot_${idx}`,
    name: `CardSlot_${idx}`,
    raycastTarget: true,
    interactable: true,
    transformByPlatform: makeTransform({
      offset: [offsetX, 0],
      size: [124, 80],
      pivot: [0.5, 0.5]
    }),
    children: [
      createTextbox({
        id: `card_cd_txt_${idx}`,
        name: 'CdText',
        text: '',
        visible: false,
        fontSize: 18,
        fontColor: parseColor('#f8fafc'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [120, 76],
          pivot: [0.5, 0.5]
        })
      }),
      createNode('image', {
        id: `card_cd_mask_${idx}`,
        name: 'CdMask',
        visible: false,
        imageId: 100001,
        imageColor: parseColor('#000000', 0.75),
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [120, 76],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `card_cost_${idx}`,
        name: 'CostText',
        text: '2点',
        fontSize: 12,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, -16],
          size: [120, 24],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `card_name_${idx}`,
        name: 'NameText',
        text: '千风庇护',
        fontSize: 14,
        fontColor: parseColor('#f8fafc'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, 14],
          size: [120, 28],
          pivot: [0.5, 0.5]
        })
      }),
      createNode('image', {
        id: `card_inner_bg_${idx}`,
        name: 'Bg',
        imageId: 100001,
        imageColor: parseColor('#1e293b'),
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [120, 76],
          pivot: [0.5, 0.5]
        })
      }),
      createNode('image', {
        id: `card_border_${idx}`,
        name: 'Border',
        imageId: 100001,
        imageColor: parseColor('#fbbf24'),
        transformByPlatform: makeTransform({ layout: 'stretch' })
      })
    ]
  });
});

const hudLayer = createNode('container', {
  id: 'hud_layer',
  name: 'HudLayer',
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
    // Toast 浮动提示
    createNode('container', {
      id: 'toast_container',
      name: 'ToastContainer',
      visible: false,
      transformByPlatform: makeTransform({
        offset: [0, 335],
        size: [520, 36],
        pivot: [0.5, 0.5]
      }),
      children: [
        createTextbox({
          id: 'toast_text',
          name: 'ToastText',
          text: '',
          fontSize: 13,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, 0],
            size: [516, 32],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'toast_inner_bg',
          name: 'ToastBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({
            offset: [0, 0],
            size: [516, 32],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'toast_border',
          name: 'ToastBorder',
          imageId: 100001,
          imageColor: parseColor('#fbbf24'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    // 底部符印栏
    createNode('container', {
      id: 'card_bar',
      name: 'CardBar',
      transformByPlatform: makeTransform({
        offset: [0, -390],
        size: [560, 84],
        pivot: [0.5, 0.5]
      }),
      children: cardSlots
    }),
    // 顶部优势条与倒计时
    createNode('container', {
      id: 'hud_top_bar',
      name: 'HudTopBar',
      transformByPlatform: makeTransform({
        offset: [0, 405],
        size: [640, 46],
        pivot: [0.5, 0.5]
      }),
      children: [
        createTextbox({
          id: 'hud_player_pct',
          name: 'HudPlayerPct',
          text: '我方掌控 50%',
          fontSize: 13,
          fontColor: parseColor('#38bdf8'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [-200, 6],
            size: [200, 28],
            pivot: [0.5, 0.5]
          })
        }),
        createTextbox({
          id: 'hud_timer',
          name: 'HudTimer',
          text: '06:00',
          fontSize: 18,
          fontColor: parseColor('#f8fafc'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [0, 6],
            size: [140, 30],
            pivot: [0.5, 0.5]
          })
        }),
        createTextbox({
          id: 'hud_enemy_pct',
          name: 'HudEnemyPct',
          text: '敌方压制 50%',
          fontSize: 13,
          fontColor: parseColor('#f43f5e'),
          horizontalAlignment: 'Right',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({
            offset: [200, 6],
            size: [200, 28],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'bar_player',
          name: 'BarPlayer',
          imageId: 100001,
          imageColor: parseColor('#38bdf8'),
          transformByPlatform: makeTransform({
            offset: [-310, -18],
            size: [160, 6],
            pivot: [0, 0.5]
          })
        }),
        createNode('image', {
          id: 'bar_enemy',
          name: 'BarEnemy',
          imageId: 100001,
          imageColor: parseColor('#f43f5e'),
          transformByPlatform: makeTransform({
            offset: [310, -18],
            size: [160, 6],
            pivot: [1, 0.5]
          })
        }),
        createNode('image', {
          id: 'bar_track',
          name: 'BarTrack',
          imageId: 100001,
          imageColor: parseColor('#334155'),
          transformByPlatform: makeTransform({
            offset: [0, -18],
            size: [620, 6],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'hud_inner_bg',
          name: 'HudBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({
            offset: [0, 0],
            size: [636, 42],
            pivot: [0.5, 0.5]
          })
        }),
        createNode('image', {
          id: 'hud_border',
          name: 'HudBorder',
          imageId: 100001,
          imageColor: parseColor('#38bdf8'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    })
  ]
});

// 5. 全屏光标输入检测层 GlobalCursorArea
const globalCursorArea = createNode('cursor', {
  id: 'global_cursor_area',
  name: 'GlobalCursorArea',
  raycastTarget: true,
  transformByPlatform: makeTransform({ layout: 'stretch' })
});

// 6. 拖拽引导虚线 DragLine (使用 anchor: [0, 0])
const dragLine = createNode('image', {
  id: 'drag_line',
  name: 'DragLine',
  visible: false,
  imageId: 100001,
  imageColor: parseColor('#fbbf24'),
  transformByPlatform: makeTransform({
    anchor: [0, 0],
    offset: [0, 0],
    size: [100, 3],
    pivot: [0, 0.5]
  })
});

// 7. 地脉灵穴层 NodesLayer (5 个地脉节点，使用 anchor: [0, 0])
const nodeGroups = NODES_DEF.map(n => {
  const factionColor = n.faction === 'player' ? '#38bdf8' : (n.faction === 'enemy' ? '#f43f5e' : '#94a3b8');
  const anomText = n.anom === 'AMBER_MINE' ? '【石珀晶矿】' : (n.anom === 'WIND_FLOW' ? '【疾风流道】' : (n.anom === 'MIST_RUINS' ? '【迷雾荒墟】' : ''));

  return createNode('container', {
    id: `node_grp_${n.id}`,
    name: `NodeGroup_${n.id}`,
    transformByPlatform: makeTransform({
      anchor: [0, 0],
      offset: [n.x, n.y],
      size: [n.r * 2, n.r * 2],
      pivot: [0.5, 0.5]
    }),
    children: [
      createTextbox({
        id: `status_txt_${n.id}`,
        name: 'StatusText',
        text: '[驻阵固守]',
        visible: false,
        fontSize: 11,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, -(n.r + 14)],
          size: [150, 26],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `anom_txt_${n.id}`,
        name: 'AnomalyText',
        text: anomText,
        visible: Boolean(anomText),
        fontSize: 12,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, n.r + 14],
          size: [130, 24],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `part_txt_${n.id}`,
        name: 'ParticleText',
        text: String(n.parts),
        fontSize: 20,
        fontColor: parseColor('#f8fafc'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, -12],
          size: [130, 32],
          pivot: [0.5, 0.5]
        })
      }),
      createTextbox({
        id: `title_txt_${n.id}`,
        name: 'TitleText',
        text: n.name,
        fontSize: 14,
        fontColor: parseColor('#f8fafc'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({
          offset: [0, 12],
          size: [130, 28],
          pivot: [0.5, 0.5]
        })
      }),
      // 固守/免伤金环 (使用 ring 图元 100006)
      createNode('image', {
        id: `defense_ring_${n.id}`,
        name: 'DefenseRing',
        visible: false,
        imageId: 100006,
        imageColor: parseColor('#fbbf24'),
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [n.r * 2 + 12, n.r * 2 + 12],
          pivot: [0.5, 0.5]
        })
      }),
      // 共鸣外环 (使用 circle 100002 + Radial360 填充)
      createNode('image', {
        id: `res_ring_${n.id}`,
        name: 'ResonanceRing',
        imageId: 100002,
        imageColor: parseColor(factionColor),
        enableFill: true,
        fillType: 'Radial360',
        fillAmount: n.ctrl / 100,
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [n.r * 2, n.r * 2],
          pivot: [0.5, 0.5]
        })
      }),
      // 灵穴底盘 (使用 circle 100002)
      createNode('image', {
        id: `base_disc_${n.id}`,
        name: 'BaseDisc',
        imageId: 100002,
        imageColor: parseColor('#0f172a'),
        transformByPlatform: makeTransform({
          offset: [0, 0],
          size: [n.r * 2, n.r * 2],
          pivot: [0.5, 0.5]
        })
      })
    ]
  });
});

const nodesLayer = createNode('container', {
  id: 'nodes_layer',
  name: 'NodesLayer',
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: nodeGroups
});

// 8. 微粒精灵池 ParticlesLayer (80 个微粒，使用 circle 100002 与 anchor: [0, 0])
const particleChildren = [];
for (let i = 1; i <= 80; i++) {
  particleChildren.push(createNode('image', {
    id: `p_${i}`,
    name: `P_${i}`,
    visible: false,
    imageId: 100002,
    imageColor: parseColor('#38bdf8'),
    transformByPlatform: makeTransform({
      anchor: [0, 0],
      offset: [0, 0],
      size: [8, 8],
      pivot: [0.5, 0.5]
    })
  }));
}

const particlesLayer = createNode('container', {
  id: 'particles_layer',
  name: 'ParticlesLayer',
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: particleChildren
});

// 9. 光轨拓扑层 LinksLayer (动态航线与静态连线，使用 rect 100001 与 anchor: [0, 0])
const linkChildren = [];
// 10 条动态流动光轨
for (let i = 1; i <= 10; i++) {
  linkChildren.push(createNode('image', {
    id: `route_line_${i}`,
    name: `RouteLine_${i}`,
    visible: false,
    imageId: 100001,
    imageColor: parseColor('#38bdf8'),
    transformByPlatform: makeTransform({
      anchor: [0, 0],
      offset: [0, 0],
      size: [100, 4],
      pivot: [0, 0.5]
    })
  }));
}
// 7 条静态拓扑底轨
LINKS_DEF.forEach(([fromId, toId], idx) => {
  const nA = NODES_DEF[fromId];
  const nB = NODES_DEF[toId];
  const dx = nB.x - nA.x;
  const dy = nB.y - nA.y;
  const dist = Math.hypot(dx, dy);
  const angle = Math.atan2(dy, dx) * 180 / Math.PI;

  linkChildren.push(createNode('image', {
    id: `static_link_${idx}`,
    name: `StaticLink_${idx}`,
    imageId: 100001,
    imageColor: parseColor('#334155'),
    transformByPlatform: makeTransform({
      anchor: [0, 0],
      offset: [nA.x, nA.y],
      size: [dist, 2],
      pivot: [0, 0.5],
      rotationZ: angle
    })
  }));
});

const linksLayer = createNode('container', {
  id: 'links_layer',
  name: 'LinksLayer',
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: linkChildren
});

// 10. 宇宙星盘底图 BgImage (最底层)
const bgImage = createNode('image', {
  id: 'bg_image',
  name: 'BgImage',
  imageId: 100001,
  imageColor: parseColor('#0b111e'),
  transformByPlatform: makeTransform({ layout: 'stretch' })
});

// 组装 GameRoot (同级子节点从前到后排序：顶层在前，底层在后)
const gameRootChildren = [
  settleModal,
  prepareModal,
  dialogueModal,
  hudLayer,
  globalCursorArea,
  dragLine,
  nodesLayer,
  particlesLayer,
  linksLayer,
  bgImage
];

// 读取打包后的 bundle 代码
const bundleLua = fs.readFileSync('/opt/starlink/src/bundle.lua', 'utf8');

// 构造 Authoring Seed
const seed = {
  format: 'qxqy-simulator-save',
  version: 4,
  meta: {
    name: '星轨交错：地脉争锋',
    sourceFormat: 'authoring',
    sourceFile: 'starlink.save.json'
  },
  activeAssetType: 'server-control-template',
  assets: {
    server: {
      version: 1,
      meta: { name: '服务端UI', assetType: 'server-control-template' },
      canvasId: 'pc-16-9',
      selectedId: 'n1',
      root: {
        id: 'sc1',
        kind: 'server-container',
        name: '客户端控件容器',
        guid: 1073741850,
        active: true,
        visible: true,
        showCursor: true,
        transformByPlatform: makeTransform({ layout: 'stretch' }),
        children: [
          {
            id: 'n1',
            kind: 'container',
            name: 'GameRoot',
            guid: 1073741851,
            active: true,
            visible: true,
            showCursor: true,
            transformByPlatform: makeTransform({ layout: 'stretch' }),
            children: gameRootChildren
          }
        ]
      }
    },
    client: {
      version: 1,
      meta: { name: '客户端模板', assetType: 'client-control-template' },
      canvasId: 'pc-16-9',
      selectedId: 'c_n1',
      root: {
        id: 'sc1',
        kind: 'server-container',
        name: '客户端控件容器',
        guid: 1073741852,
        children: [
          {
            id: 'c_n1',
            kind: 'container',
            name: '客户端模板根',
            guid: 1073741853,
            children: []
          }
        ]
      }
    },
    scripts: [
      {
        id: '1073742100',
        guid: 1073742100,
        path: 'src/main.lua',
        source: bundleLua,
        controlId: 'n1',
        controlAsset: 'server-control-template',
        controlName: 'GameRoot',
        assetType: 'server-control-template',
        assetLabel: '服务器控件模板',
        mounted: true
      }
    ]
  }
};

const studio = createStudio(seed);
const snap = studio.get();
console.log('Project built! Total controls in tree:', snap.tree.length);

const outSaveData = Buffer.from(studio.exportData('save').data, 'base64').toString('utf8');
fs.writeFileSync('/opt/starlink/starlink.save.json', outSaveData, 'utf8');
console.log('Saved to /opt/starlink/starlink.save.json, file size:', outSaveData.length);

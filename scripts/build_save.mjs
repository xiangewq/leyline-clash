// scripts/build_save.mjs
// 构建《星轨交错：地脉争锋》全量 UI 控件树与工程存档 starlink.save.json
// 支持全 5 大战役章节、18 灵穴拓扑池、45 静态拓扑连线、25 动态航线、120 微粒池与模式/章节选择面板

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

// 6 备选战术卡 (按消耗权能升序排列：2点 -> 2点 -> 3点 -> 4点 -> 4点 -> 5点)
const POOL_CARDS = [
  { id: 1, key: 'anemo_shield', name: '千风庇护', cost: 2, cd: 30, desc: '加持免伤结界' },
  { id: 2, key: 'pyro_erosion', name: '烈焰侵蚀', cost: 2, cd: 30, desc: '削减40%敌方微粒' },
  { id: 3, key: 'anemo_turb', name: '千风湍流', cost: 3, cd: 20, desc: '流道速度翻倍' },
  { id: 4, key: 'pyro_blast', name: '轰轰烈焰', cost: 4, cd: 25, desc: '消灭80%敌方微粒' },
  { id: 5, key: 'geo_wall', name: '坚岩重嶂', cost: 4, cd: 30, desc: '战损减半反震' },
  { id: 6, key: 'hydro_bribe', name: '摩拉律法', cost: 5, cd: 35, desc: '秒占中立灵穴' },
];

// ==========================================
// 千星奇域渲染规则：同级节点按照 FRONT-TO-BACK (从前往后) 绘制
// 第 0 个子节点处于最顶层 (Front / On Top)
// 最后一个子节点处于最底层 (Back / Underneath)
// ==========================================

function createTextbox(opts) {
  return createNode('textbox', {
    ...opts,
    minimumFontSize: opts.minimumFontSize ?? Math.min(opts.fontSize || 12, 10),
    enableOutline: false,
    bgColor: 0
  });
}

// 0. 模式选择主界面 ModeSelectModal (最顶层)
const modeSelectModal = createNode('container', {
  id: 'mode_select_modal',
  name: 'ModeSelectModal',
  visible: true,
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
    createNode('container', {
      id: 'mode_box',
      name: 'ModeBox',
      transformByPlatform: makeTransform({
        offset: [0, 0],
        size: [840, 520],
        pivot: [0.5, 0.5]
      }),
      children: [
        // 模式 1: 剧情模式按钮
        createNode('button', {
          id: 'mode_story_btn',
          name: 'ModeStoryBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [-190, -45],
            size: [320, 240],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'mode_story_desc',
              name: 'DescText',
              text: '体验提瓦特古代沙盘推衍\n5大递进章节 · 权能逐步觉醒\n2~4方全域大乱斗争霸',
              fontSize: 13,
              fontColor: parseColor('#94a3b8'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, -50], size: [280, 70], pivot: [0.5, 0.5] })
            }),
            createTextbox({
              id: 'mode_story_sub',
              name: 'SubText',
              text: '【5 章节战役推衍】',
              fontSize: 14,
              fontColor: parseColor('#38bdf8'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 18], size: [280, 28], pivot: [0.5, 0.5] })
            }),
            createTextbox({
              id: 'mode_story_title',
              name: 'TitleText',
              text: '【 剧情模式 】',
              fontSize: 24,
              fontColor: parseColor('#f8fafc'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 65], size: [280, 42], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'mode_story_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#1e3a5f'),
              transformByPlatform: makeTransform({ offset: [0, 0], size: [312, 232], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'mode_story_border',
              name: 'BtnBorder',
              imageId: 100001,
              imageColor: parseColor('#38bdf8'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),

        // 模式 2: 挑战模式按钮 (待完成)
        createNode('button', {
          id: 'mode_challenge_btn',
          name: 'ModeChallengeBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [190, -45],
            size: [320, 240],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'mode_challenge_desc',
              name: 'DescText',
              text: '全域混沌异象随机轮换\n极高难度深渊AI演练\n（待完成 · 敬请期待）',
              fontSize: 13,
              fontColor: parseColor('#64748b'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, -50], size: [280, 70], pivot: [0.5, 0.5] })
            }),
            createTextbox({
              id: 'mode_challenge_sub',
              name: 'SubText',
              text: '【全域无尽深渊】',
              fontSize: 14,
              fontColor: parseColor('#a855f7'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 18], size: [280, 28], pivot: [0.5, 0.5] })
            }),
            createTextbox({
              id: 'mode_challenge_title',
              name: 'TitleText',
              text: '【 挑战模式 】',
              fontSize: 24,
              fontColor: parseColor('#94a3b8'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 65], size: [280, 42], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'mode_challenge_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#181e2b'),
              transformByPlatform: makeTransform({ offset: [0, 0], size: [312, 232], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'mode_challenge_border',
              name: 'BtnBorder',
              imageId: 100001,
              imageColor: parseColor('#475569'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),

        createTextbox({
          id: 'mode_subtitle',
          name: 'ModeSubtitle',
          text: '坎瑞亚古代战争推衍棋盘 · 提瓦特元素法则战争模拟',
          fontSize: 14,
          fontColor: parseColor('#94a3b8'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 160], size: [600, 30], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'mode_title',
          name: 'ModeTitle',
          text: '《星轨交错：地脉争锋》',
          fontSize: 30,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 210], size: [600, 50], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'mode_inner_bg',
          name: 'ModeInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [832, 512], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'mode_border',
          name: 'ModeBorder',
          imageId: 100001,
          imageColor: parseColor('#fbbf24'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    createNode('image', {
      id: 'mode_mask',
      name: 'ModeMask',
      imageId: 100001,
      imageColor: parseColor('#000000', 0.85),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

// 1. 关卡章节选择面板 ChapterSelectModal
const chapterCardNodes = [1, 2, 3, 4, 5].map(idx => {
  const posX = -380 + (idx - 1) * 190;
  return createNode('button', {
    id: `chapter_card_${idx}`,
    name: `ChapterCard_${idx}`,
    raycastTarget: true,
    interactable: true,
    transformByPlatform: makeTransform({
      offset: [posX, 35],
      size: [175, 230],
      pivot: [0.5, 0.5]
    }),
    children: [
      createTextbox({
        id: `chap_tag_${idx}`,
        name: 'TagText',
        text: idx === 1 ? '【★ 当前选择】' : '【锁定中】',
        fontSize: 11,
        fontColor: parseColor(idx === 1 ? '#fbbf24' : '#64748b'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, -85], size: [160, 24], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `chap_info_${idx}`,
        name: 'InfoText',
        text: `${Math.min(4, Math.floor((idx + 2) / 1.5))}方混战 | ${8 + idx * 2}灵穴`,
        fontSize: 12,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, -35], size: [160, 24], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `chap_budget_${idx}`,
        name: 'BudgetText',
        text: `权能预算: ${2 + idx * 2} 点`,
        fontSize: 12,
        fontColor: parseColor('#38bdf8'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, 5], size: [160, 24], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `chap_title_${idx}`,
        name: 'TitleText',
        text: `第 ${idx} 关`,
        fontSize: 17,
        fontColor: parseColor(idx === 1 ? '#f8fafc' : '#94a3b8'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, 65], size: [160, 32], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `chap_bg_${idx}`,
        name: 'CardBg',
        imageId: 100001,
        imageColor: parseColor(idx === 1 ? '#1e3a5f' : '#0f172a'),
        transformByPlatform: makeTransform({ offset: [0, 0], size: [169, 224], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `chap_bdr_${idx}`,
        name: 'CardBorder',
        imageId: 100001,
        imageColor: parseColor(idx === 1 ? '#fbbf24' : '#334155'),
        transformByPlatform: makeTransform({ layout: 'stretch' })
      })
    ]
  });
});

const chapterSelectModal = createNode('container', {
  id: 'chapter_select_modal',
  name: 'ChapterSelectModal',
  visible: false,
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
    createNode('container', {
      id: 'chap_box',
      name: 'ChapBox',
      transformByPlatform: makeTransform({
        offset: [0, 0],
        size: [1020, 560],
        pivot: [0.5, 0.5]
      }),
      children: [
        // 底部返回按钮
        createNode('button', {
          id: 'chap_back_btn',
          name: 'ChapterBackBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [-180, -215],
            size: [180, 44],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'chap_back_txt',
              name: 'Text',
              text: '【返回模式选择】',
              fontSize: 14,
              fontColor: parseColor('#94a3b8'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 0], size: [180, 44], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'chap_back_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#1e293b'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),

        // 底部出征按钮
        createNode('button', {
          id: 'chap_start_btn',
          name: 'ChapterStartBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [140, -215],
            size: [240, 44],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'chap_start_txt',
              name: 'Text',
              text: '【启程出征 · 第 1 关】',
              fontSize: 16,
              fontColor: parseColor('#f8fafc'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 0], size: [240, 44], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'chap_start_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#0284c7'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),

        // 选中章节描述详情
        createTextbox({
          id: 'chap_desc',
          name: 'ChapterDesc',
          text: '【第 1 关·启蒙·清泉流响】\n单线对冲 · 基础地脉流动新手演练\n清泉镇下汇聚着温和的地脉微粒。在此熟悉光轨铺设与驻阵固守，击溃愚人众前哨。',
          fontSize: 13,
          fontColor: parseColor('#e2e8f0'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, -130], size: [880, 60], pivot: [0.5, 0.5] })
        }),

        ...chapterCardNodes,

        createTextbox({
          id: 'chap_title',
          name: 'ChapterTitle',
          text: '【战役推衍 · 章节选择】',
          fontSize: 22,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 220], size: [500, 40], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'chap_inner_bg',
          name: 'ChapInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [1012, 552], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'chap_border',
          name: 'ChapBorder',
          imageId: 100001,
          imageColor: parseColor('#38bdf8'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    createNode('image', {
      id: 'chap_mask',
      name: 'ChapMask',
      imageId: 100001,
      imageColor: parseColor('#000000', 0.80),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

// 2. 终局结算弹窗 SettleModal
const settleModal = createNode('container', {
  id: 'settle_modal',
  name: 'SettleModal',
  visible: false,
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
    createNode('container', {
      id: 'settle_box',
      name: 'SettleBox',
      transformByPlatform: makeTransform({
        offset: [0, 0],
        size: [680, 400],
        pivot: [0.5, 0.5]
      }),
      children: [
        // 进军下一关按钮 (胜利时呈现)
        createNode('button', {
          id: 'settle_next_btn',
          name: 'SettleNextBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [-190, -125],
            size: [160, 44],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'settle_next_txt',
              name: 'Text',
              text: '【进军下一关】',
              fontSize: 14,
              fontColor: parseColor('#f8fafc'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 0], size: [160, 44], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'settle_next_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#0284c7'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),

        // 重新演练按钮
        createNode('button', {
          id: 'settle_retry_btn',
          name: 'SettleRetryBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [0, -125],
            size: [160, 44],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'settle_retry_txt',
              name: 'Text',
              text: '【重新演练】',
              fontSize: 14,
              fontColor: parseColor('#f8fafc'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 0], size: [160, 44], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'settle_retry_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#1e3a5f'),
              transformByPlatform: makeTransform({ layout: 'stretch' })
            })
          ]
        }),

        // 返回章节选择按钮
        createNode('button', {
          id: 'settle_chap_btn',
          name: 'SettleChapterBtn',
          raycastTarget: true,
          interactable: true,
          transformByPlatform: makeTransform({
            offset: [190, -125],
            size: [160, 44],
            pivot: [0.5, 0.5]
          }),
          children: [
            createTextbox({
              id: 'settle_chap_txt',
              name: 'Text',
              text: '【章节选择】',
              fontSize: 14,
              fontColor: parseColor('#94a3b8'),
              horizontalAlignment: 'Middle',
              verticalAlignment: 'Middle',
              transformByPlatform: makeTransform({ offset: [0, 0], size: [160, 44], pivot: [0.5, 0.5] })
            }),
            createNode('image', {
              id: 'settle_chap_bg',
              name: 'BtnBg',
              imageId: 100001,
              imageColor: parseColor('#334155'),
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
          transformByPlatform: makeTransform({ offset: [0, -40], size: [560, 36], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'settle_desc',
          name: 'SettleDesc',
          text: '星盘之理尽在掌控，地脉灵流归于统御。全域敌对势力已被彻底肃清！',
          fontSize: 14,
          fontColor: parseColor('#e2e8f0'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 35], size: [560, 50], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'settle_title',
          name: 'SettleTitle',
          text: '【推衍大捷·全域共鸣】',
          fontSize: 24,
          fontColor: parseColor('#38bdf8'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 125], size: [520, 44], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'settle_inner_bg',
          name: 'SettleInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [672, 392], pivot: [0.5, 0.5] })
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
    createNode('image', {
      id: 'settle_mask',
      name: 'SettleMask',
      imageId: 100001,
      imageColor: parseColor('#000000', 0.75),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

// 3. 战前调配弹窗 PrepareModal
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
        text: idx < 2 ? '【✓ 已装配】' : '【点击装配】',
        fontSize: 11,
        fontColor: parseColor(idx < 2 ? '#fbbf24' : '#64748b'),
        horizontalAlignment: 'Right',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [45, 24], size: [90, 24], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `prep_cost_${card.id}`,
        name: 'CostText',
        text: `消耗: ${card.cost} 权能  |  CD: ${card.cd}秒`,
        fontSize: 12,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, -28], size: [180, 24], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `prep_desc_${card.id}`,
        name: 'DescText',
        text: card.desc,
        fontSize: 11,
        fontColor: parseColor('#94a3b8'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, -4], size: [180, 28], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `prep_name_${card.id}`,
        name: 'NameText',
        text: card.name,
        fontSize: 14,
        fontColor: parseColor(idx < 2 ? '#f8fafc' : '#94a3b8'),
        horizontalAlignment: 'Left',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [-30, 24], size: [110, 28], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `prep_cbg_${card.id}`,
        name: 'CardBg',
        imageId: 100001,
        imageColor: parseColor(idx < 2 ? '#1e3a5f' : '#0f172a'),
        transformByPlatform: makeTransform({ offset: [0, 0], size: [194, 90], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `prep_cbdr_${card.id}`,
        name: 'CardBorder',
        imageId: 100001,
        imageColor: parseColor(idx < 2 ? '#fbbf24' : '#475569'),
        transformByPlatform: makeTransform({ offset: [0, 0], size: [200, 96], pivot: [0.5, 0.5] })
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
              transformByPlatform: makeTransform({ offset: [0, 0], size: [220, 46], pivot: [0.5, 0.5] })
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
          text: '已选符印：千风庇护(2点)',
          fontSize: 13,
          fontColor: parseColor('#94a3b8'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 95], size: [600, 28], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'prep_budget_txt',
          name: 'PrepBudgetText',
          text: '当前调配权能预算：2 / 4 点',
          fontSize: 15,
          fontColor: parseColor('#38bdf8'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 130], size: [400, 32], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'prep_title',
          name: 'PrepTitle',
          text: '【战前符印调配】',
          fontSize: 20,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 175], size: [400, 40], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'prep_inner_bg',
          name: 'PrepInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [754, 454], pivot: [0.5, 0.5] })
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

// 4. 剧情弹窗 DialogueModal
const dialogueModal = createNode('container', {
  id: 'dialogue_modal',
  name: 'DialogueModal',
  visible: false,
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
              transformByPlatform: makeTransform({ offset: [0, 0], size: [88, 34], pivot: [0.5, 0.5] })
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
              transformByPlatform: makeTransform({ offset: [0, 0], size: [88, 34], pivot: [0.5, 0.5] })
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
          text: '哇！阿贝多，这个泛着蓝光的大圆盘是什么呀？\n上面亮晶晶的小圆点，看起来好像……会发光的甜甜花糖豆！',
          fontSize: 15,
          fontColor: parseColor('#f8fafc'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Top',
          transformByPlatform: makeTransform({ offset: [0, -6], size: [820, 72], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'dlg_speaker',
          name: 'DlgSpeaker',
          text: '【派蒙】',
          fontSize: 18,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [-300, 48], size: [220, 36], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'dlg_inner_bg',
          name: 'DlgInnerBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [874, 164], pivot: [0.5, 0.5] })
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

// 5. 顶部 HUD 与底部符印栏 HudLayer
const cardSlots = [1, 2, 3, 4].map(idx => {
  const offsetX = -210 + (idx - 1) * 140;
  return createNode('button', {
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
        transformByPlatform: makeTransform({ offset: [0, 0], size: [120, 76], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `card_cd_mask_${idx}`,
        name: 'CdMask',
        visible: false,
        imageId: 100001,
        imageColor: parseColor('#000000', 0.75),
        transformByPlatform: makeTransform({ offset: [0, 0], size: [120, 76], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `card_cost_${idx}`,
        name: 'CostText',
        text: '2点 · CD 30s',
        fontSize: 11,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, -16], size: [120, 24], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `card_name_${idx}`,
        name: 'NameText',
        text: '千风庇护',
        fontSize: 14,
        fontColor: parseColor('#f8fafc'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, 14], size: [120, 28], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `card_inner_bg_${idx}`,
        name: 'Bg',
        imageId: 100001,
        imageColor: parseColor('#1e293b'),
        transformByPlatform: makeTransform({ offset: [0, 0], size: [120, 76], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `card_border_${idx}`,
        name: 'CardBorder',
        imageId: 100001,
        imageColor: parseColor('#fbbf24'),
        transformByPlatform: makeTransform({ layout: 'stretch' })
      })
    ]
  });
});

// 全局浮动播报条 ToastContainer (置于 GameRoot 最顶层第 0 节点，绝不被任何弹窗/遮罩层遮挡)
const toastContainer = createNode('container', {
  id: 'toast_container',
  name: 'ToastContainer',
  visible: false,
  transformByPlatform: makeTransform({
    offset: [0, 335],
    size: [600, 42],
    pivot: [0.5, 0.5]
  }),
  children: [
    createTextbox({
      id: 'toast_text',
      name: 'ToastText',
      text: '',
      fontSize: 14,
      fontColor: parseColor('#fbbf24'),
      horizontalAlignment: 'Middle',
      verticalAlignment: 'Middle',
      transformByPlatform: makeTransform({ offset: [0, 0], size: [592, 38], pivot: [0.5, 0.5] })
    }),
    createNode('image', {
      id: 'toast_inner_bg',
      name: 'ToastBg',
      imageId: 100001,
      imageColor: parseColor('#090d16', 0.95),
      transformByPlatform: makeTransform({ offset: [0, 0], size: [594, 40], pivot: [0.5, 0.5] })
    }),
    createNode('image', {
      id: 'toast_border',
      name: 'ToastBorder',
      imageId: 100001,
      imageColor: parseColor('#fbbf24'),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

// 全局战前3秒倒计时 CountdownModal (置于 GameRoot 顶层，大字震撼呈现 3、2、1、开始)
const countdownModal = createNode('container', {
  id: 'countdown_modal',
  name: 'CountdownModal',
  visible: false,
  transformByPlatform: makeTransform({
    offset: [0, 50],
    size: [440, 180],
    pivot: [0.5, 0.5]
  }),
  children: [
    createTextbox({
      id: 'countdown_text',
      name: 'CountdownText',
      text: '3',
      fontSize: 68,
      fontColor: parseColor('#fbbf24'),
      horizontalAlignment: 'Middle',
      verticalAlignment: 'Middle',
      transformByPlatform: makeTransform({ offset: [0, 18], size: [400, 80], pivot: [0.5, 0.5] })
    }),
    createTextbox({
      id: 'countdown_sub',
      name: 'CountdownSub',
      text: '星图推衍即将开启...',
      fontSize: 14,
      fontColor: parseColor('#38bdf8'),
      horizontalAlignment: 'Middle',
      verticalAlignment: 'Middle',
      transformByPlatform: makeTransform({ offset: [0, -48], size: [400, 28], pivot: [0.5, 0.5] })
    }),
    createNode('image', {
      id: 'countdown_inner_bg',
      name: 'CountdownBg',
      imageId: 100001,
      imageColor: parseColor('#090d16', 0.94),
      transformByPlatform: makeTransform({ offset: [0, 0], size: [434, 174], pivot: [0.5, 0.5] })
    }),
    createNode('image', {
      id: 'countdown_border',
      name: 'CountdownBorder',
      imageId: 100001,
      imageColor: parseColor('#fbbf24'),
      transformByPlatform: makeTransform({ layout: 'stretch' })
    })
  ]
});

const hudLayer = createNode('container', {
  id: 'hud_layer',
  name: 'HudLayer',
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: [
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
          transformByPlatform: makeTransform({ offset: [-200, 6], size: [200, 28], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'hud_timer',
          name: 'HudTimer',
          text: '03:00',
          fontSize: 18,
          fontColor: parseColor('#f8fafc'),
          horizontalAlignment: 'Middle',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [0, 6], size: [140, 30], pivot: [0.5, 0.5] })
        }),
        createTextbox({
          id: 'hud_enemy_pct',
          name: 'HudEnemyPct',
          text: '敌方压制 50%',
          fontSize: 13,
          fontColor: parseColor('#f43f5e'),
          horizontalAlignment: 'Right',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [200, 6], size: [200, 28], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'bar_player',
          name: 'BarPlayer',
          imageId: 100001,
          imageColor: parseColor('#38bdf8'),
          transformByPlatform: makeTransform({ offset: [-310, -18], size: [160, 6], pivot: [0, 0.5] })
        }),
        createNode('image', {
          id: 'bar_enemy',
          name: 'BarEnemy',
          imageId: 100001,
          imageColor: parseColor('#f43f5e'),
          transformByPlatform: makeTransform({ offset: [310, -18], size: [160, 6], pivot: [1, 0.5] })
        }),
        createNode('image', {
          id: 'bar_track',
          name: 'BarTrack',
          imageId: 100001,
          imageColor: parseColor('#334155'),
          transformByPlatform: makeTransform({ offset: [0, -18], size: [620, 6], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'hud_inner_bg',
          name: 'HudBg',
          imageId: 100001,
          imageColor: parseColor('#0f172a'),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [636, 42], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'hud_border',
          name: 'HudBorder',
          imageId: 100001,
          imageColor: parseColor('#38bdf8'),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    // 左上角固定位置：关卡特殊灵穴效果说明
    createNode('container', {
      id: 'hud_anomaly_box',
      name: 'HudAnomalyBox',
      transformByPlatform: makeTransform({
        offset: [-580, 405],
        size: [380, 78],
        pivot: [0.5, 0.5]
      }),
      children: [
        createTextbox({
          id: 'hud_anomaly_title',
          name: 'AnomalyTitle',
          text: '【地脉情报】',
          fontSize: 12,
          fontColor: parseColor('#38bdf8'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [-170, 22], size: [340, 20], pivot: [0, 0.5] })
        }),
        createTextbox({
          id: 'hud_anomaly_desc',
          name: 'AnomalyDesc',
          text: '● 标准地脉：常规孕育与输送，前线激战，后方休整',
          fontSize: 10,
          fontColor: parseColor('#cbd5e1'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [-170, -10], size: [340, 38], pivot: [0, 0.5] })
        }),
        createNode('image', {
          id: 'hud_anomaly_inner_bg',
          name: 'AnomalyBg',
          imageId: 100001,
          imageColor: parseColor('#090d16', 0.9),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [376, 74], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'hud_anomaly_border',
          name: 'AnomalyBorder',
          imageId: 100001,
          imageColor: parseColor('#38bdf8', 0.6),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    }),
    // 右上角固定位置：连线与符印释放简要操作说明
    createNode('container', {
      id: 'hud_guide_box',
      name: 'HudGuideBox',
      transformByPlatform: makeTransform({
        offset: [580, 405],
        size: [380, 78],
        pivot: [0.5, 0.5]
      }),
      children: [
        createTextbox({
          id: 'hud_guide_title',
          name: 'GuideTitle',
          text: '【战术操作指引】',
          fontSize: 12,
          fontColor: parseColor('#fbbf24'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [-170, 22], size: [340, 20], pivot: [0, 0.5] })
        }),
        createTextbox({
          id: 'hud_guide_desc',
          name: 'GuideDesc',
          text: '● 连线：拖拽己方灵穴至相邻据点建立输送\n● 固守：轻点己方灵穴展开/收拢固守结界\n● 符印：点击下方符印后点击目标灵穴释放',
          fontSize: 10,
          fontColor: parseColor('#cbd5e1'),
          horizontalAlignment: 'Left',
          verticalAlignment: 'Middle',
          transformByPlatform: makeTransform({ offset: [-170, -10], size: [340, 38], pivot: [0, 0.5] })
        }),
        createNode('image', {
          id: 'hud_guide_inner_bg',
          name: 'GuideBg',
          imageId: 100001,
          imageColor: parseColor('#090d16', 0.9),
          transformByPlatform: makeTransform({ offset: [0, 0], size: [376, 74], pivot: [0.5, 0.5] })
        }),
        createNode('image', {
          id: 'hud_guide_border',
          name: 'GuideBorder',
          imageId: 100001,
          imageColor: parseColor('#fbbf24', 0.6),
          transformByPlatform: makeTransform({ layout: 'stretch' })
        })
      ]
    })
  ]
});

// 6. 全屏光标输入检测层 GlobalCursorArea
const globalCursorArea = createNode('cursor', {
  id: 'global_cursor_area',
  name: 'GlobalCursorArea',
  raycastTarget: true,
  transformByPlatform: makeTransform({ layout: 'stretch' })
});

// 7. 拖拽引导虚线 DragLine
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

// 8. 地脉灵穴层 NodesLayer (18 个全量对象池 NodeGroup_0 ~ NodeGroup_17)
const nodeGroups = [];
for (let i = 0; i < 18; i++) {
  nodeGroups.push(createNode('container', {
    id: `node_grp_${i}`,
    name: `NodeGroup_${i}`,
    visible: i < 10, // 初始第1关10个可见
    transformByPlatform: makeTransform({
      anchor: [0, 0],
      offset: [200 + i * 60, 450],
      size: [76, 76],
      pivot: [0.5, 0.5]
    }),
    children: [
      createTextbox({
        id: `status_txt_${i}`,
        name: 'StatusText',
        text: '[驻阵固守]',
        visible: false,
        fontSize: 11,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, -50], size: [150, 26], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `anom_txt_${i}`,
        name: 'AnomalyText',
        text: '',
        visible: false,
        fontSize: 12,
        fontColor: parseColor('#fbbf24'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, 50], size: [130, 24], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `part_txt_${i}`,
        name: 'ParticleText',
        text: '兵力: 0',
        fontSize: 14,
        fontColor: parseColor('#f8fafc'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, -10], size: [140, 30], pivot: [0.5, 0.5] })
      }),
      createTextbox({
        id: `title_txt_${i}`,
        name: 'TitleText',
        text: `灵穴 ${i}`,
        fontSize: 13,
        fontColor: parseColor('#f8fafc'),
        horizontalAlignment: 'Middle',
        verticalAlignment: 'Middle',
        transformByPlatform: makeTransform({ offset: [0, 14], size: [140, 28], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `defense_ring_${i}`,
        name: 'DefenseRing',
        visible: false,
        imageId: 100006,
        imageColor: parseColor('#fbbf24'),
        transformByPlatform: makeTransform({ offset: [0, 0], size: [88, 88], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `res_ring_${i}`,
        name: 'ResonanceRing',
        imageId: 100002,
        imageColor: parseColor('#38bdf8'),
        enableFill: true,
        fillType: 'Radial360',
        fillAmount: 1.0,
        transformByPlatform: makeTransform({ offset: [0, 0], size: [76, 76], pivot: [0.5, 0.5] })
      }),
      createNode('image', {
        id: `base_disc_${i}`,
        name: 'BaseDisc',
        imageId: 100002,
        imageColor: parseColor('#0f172a'),
        transformByPlatform: makeTransform({ offset: [0, 0], size: [76, 76], pivot: [0.5, 0.5] })
      })
    ]
  }));
}

const nodesLayer = createNode('container', {
  id: 'nodes_layer',
  name: 'NodesLayer',
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: nodeGroups
});

// 9. 微粒精灵池 ParticlesLayer (120 个微粒对象池 P_1 ~ P_120)
const particleChildren = [];
for (let i = 1; i <= 120; i++) {
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

// 10. 光轨拓扑层 LinksLayer (25 条动态流道 + 45 条静态底轨)
const linkChildren = [];
for (let i = 1; i <= 25; i++) {
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
for (let i = 0; i < 45; i++) {
  linkChildren.push(createNode('image', {
    id: `static_link_${i}`,
    name: `StaticLink_${i}`,
    visible: false,
    imageId: 100001,
    imageColor: parseColor('#334155'),
    transformByPlatform: makeTransform({
      anchor: [0, 0],
      offset: [0, 0],
      size: [100, 2],
      pivot: [0, 0.5]
    })
  }));
}

const linksLayer = createNode('container', {
  id: 'links_layer',
  name: 'LinksLayer',
  transformByPlatform: makeTransform({ layout: 'stretch' }),
  children: linkChildren
});

// 11. 宇宙星盘底图 BgImage (最底层)
const bgImage = createNode('image', {
  id: 'bg_image',
  name: 'BgImage',
  imageId: 100001,
  imageColor: parseColor('#0b111e'),
  transformByPlatform: makeTransform({ layout: 'stretch' })
});

// 组装 GameRoot (同级子节点从前到后排序：第 0 项在最顶层，最后一项在最底层)
const gameRootChildren = [
  toastContainer,       // <--- 最顶层 (Index 0): 全局浮动播报条，绝不被任何弹窗/遮罩层遮挡！
  countdownModal,       // <--- Index 1: 战前3秒倒计时弹窗 (3、2、1、开始)
  modeSelectModal,
  chapterSelectModal,
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

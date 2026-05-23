
## 页面类型定义

### industry（产业页面）
描述：产业链的整体概况与分析
模板位置：templates/industry.md

frontmatter 字段：
- title (required): 产业名称
- type (required): industry
- industry_chain (required): [上游, 中游, 下游]
- upstream (required): [上游环节列表]
- midstream: [中游环节列表]
- downstream (required): [下游环节列表]
- market_size: 市场规模（带单位）
- growth_rate: 同比增速
- key_players: [主要公司列表]
- policy_tags: [相关政策标签]
- related_companies: [相关公司页面链接]
- related_concepts: [相关概念页面链接]
- sources: [来源文件列表]
- created (required): YYYY-MM-DD
- updated (required): YYYY-MM-DD
- confidence: high | medium | low
- status: active | archived | draft

正文结构：
1. 产业概述（定义、边界、发展阶段）
2. 产业链图谱（上中下游结构）
3. 市场规模与增长驱动因素
4. 竞争格局分析（波特五力）
5. 关键环节与议价能力分析
6. 主要参与者概览
7. 政策环境
8. 风险因素
9. 发展趋势与投资机会
10. Related Pages

### company（公司页面）
描述：单个上市公司的深度分析
模板位置：templates/company.md

frontmatter 字段：
- title (required): 公司名称
- type (required): company
- stock_code (required): {交易所: 代码}
- industry (required): 所属产业
- sub_industry: 细分行业
- position_in_chain (required): 上游 | 中游 | 下游
- customers: [主要客户]
- suppliers: [主要供应商]
- competitors: [主要竞争对手]
- market_cap: 市值
- pe_ttm: 市盈率TTM
- pb: 市净率
- roe: 净资产收益率
- gross_margin: 毛利率
- revenue_growth: 营收增长率
- profit_growth: 净利润增长率
- related_industries: [所属产业页面链接]
- sources: [来源文件列表]
- created (required): YYYY-MM-DD
- updated (required): YYYY-MM-DD
- confidence: high | medium | low
- rating: 买入 | 增持 | 持有 | 减持 | 卖出
- target_price: 目标价（带单位）

正文结构：
1. 公司概况
2. 主营业务与产品结构
3. 产业链位置与议价能力
4. 财务分析（营收、利润、现金流、关键指标趋势）
5. 竞争优势与护城河
6. 管理层与治理结构
7. 风险因素
8. 估值分析
9. 投资评级与目标价
10. Related Pages

### concept（概念页面）
描述：投研方法论、分析框架、财务指标解释
frontmatter: title, type, category, description, related_concepts, applications

### comparison（对比页面）
描述：公司对比、产业对比、指标对比
frontmatter: title, type, entities, dimensions, verdict, sources

### synthesis（综合报告）
描述：基于知识库多篇页面综合生成的研究报告
frontmatter: title, type, topic, key_findings, recommendations, risk_factors
```
# GitHub Fitness/Health/Readiness 開源項目研究

## 高 Stars 項目（值得參考）

### 1. **thomaschampagne/elevate** — 1,437 ⭐
- **類型**: 運動數據分析平台（Web + Browser Extension）
- **特點**: 深度分析 Strava 數據，追蹤 fitness progression over time
- **可參考**: 
  - 長期趨勢分析（fitness progression / fatigue accumulation）
  - 多維度數據可視化（power curve, heart rate zones）
  - 訓練負荷 vs 恢復平衡模型
- **應用**: 加入 fitness trend line（7-day / 30-day / 90-day rolling average）

### 2. **maxkonovalov/MKRingProgressView** — 1,571 ⭐
- **類型**: Swift 環形進度條組件
- **特點**: Apple Watch Activity app 風格的三環設計
- **可參考**:
  - 三環重疊設計（Move / Exercise / Stand）
  - 漸層色環 + 發光效果
  - 動畫化進度更新
- **應用**: Dashboard hero section 可用三環顯示 Gym / Work / Sleep

### 3. **karimknaebel/Iron** — 218 ⭐
- **類型**: iOS 舉重訓練追蹤（SwiftUI）
- **特點**: 現代 SwiftUI 設計，完全免費
- **可參考**:
  - 簡潔的訓練記錄 UI
  - 組數 x 次數 x 重量輸入
  - 訓練歷史時間線
- **應用**: 未來加入 workout logging 功能

### 4. **karthironald/BodyProgress** — 274 ⭐
- **類型**: iOS 健身進度追蹤（Widget 支援）
- **特點**: Widget 顯示進度，照片對比
- **可參考**:
  - iOS Widget 設計（small / medium / large）
  - 照片 before/after 對比
  - 進度百分比顯示
- **應用**: 加入 iOS Widget 顯示 readiness score

### 5. **DanielJamesTronca/SleepChartKit** — 234 ⭐
- **類型**: SwiftUI 睡眠分析圖表
- **特點**: 高精度複製 Apple 睡眠分析圖表
- **可參考**:
  - 睡眠階段分段條形圖（deep / REM / light / awake）
  - 時間軸對齊
  - 純 SwiftUI 實現
- **應用**: 直接參考睡眠階段可視化設計

### 6. **Aura-healthcare/hrv-analysis** — 449 ⭐
- **類型**: Python HRV 分析庫
- **特點**: 完整的 HRV 時域/頻域/非線性分析
- **可參考**:
  - RMSSD / SDNN / pNN50 計算
  - 頻域分析（LF / HF / LFHF ratio）
  - 非線性分析（Poincaré plot, DFA）
- **應用**: 未來加入進階 HRV 指標

### 7. **PGomes92/pyhrv** — 333 ⭐
- **類型**: Python HRV 工具箱
- **特點**: 專注 HRV 分析，含圖表生成
- **可參考**:
  - Poincaré plot（散點圖顯示 RR interval 分佈）
  - 呼吸頻率估計
  - HRV 報告生成
- **應用**: 加入 Poincaré plot 顯示 HRV 變異性

### 8. **JanCBrammer/OpenHRV** — 172 ⭐
- **類型**: HRV biofeedback 桌面應用
- **特點**: 實時 HRV 反饋，ECG chest strap 支援
- **可參考**:
  - 實時 HRV 曲線顯示
  - 呼吸引導動畫
  - Biofeedback 訓練模式
- **應用**: 加入呼吸訓練 / HRV coherence 模式

### 9. **ahmetb/personal-dashboard** — 334 ⭐
- **類型**: 個人數據儀表板
- **特點**: 自動收集每日統計數據
- **可參考**:
  - 自動化數據收集流程
  - 多源數據整合（GitHub, RescueTime, 等）
  - 每日報告生成
- **應用**: 自動化 readiness 報告生成

### 10. **marekpridal/BarChart** — 81 ⭐
- **類型**: SwiftUI 條形圖庫
- **特點**: 模仿 iOS Health app 條形圖
- **可參考**:
  - 圓角條形圖
  - 漸層色填充
  - 觸摸互動（顯示數值）
- **應用**: 週/月統計條形圖

---

## 設計靈感總結

### 數據可視化創新
| 項目 | 創新點 | 應用建議 |
|------|--------|----------|
| elevate | Power curve + fitness progression | 加入 fitness trend chart |
| MKRingProgressView | 三環重疊 + 漸層發光 | Hero section 三環設計 |
| SleepChartKit | 睡眠階段分段條形圖 | 睡眠分析頁面 |
| pyhrv | Poincaré plot | HRV 詳情頁面 |
| OpenHRV | 實時曲線 + 呼吸引導 | 呼吸訓練模式 |

### UI/UX 設計模式
| 項目 | 設計特點 | 應用建議 |
|------|----------|----------|
| Iron | 簡潔 SwiftUI + 深色模式 | 整體設計語言參考 |
| BodyProgress | Widget 支援 + 照片對比 | iOS Widget + 進度追蹤 |
| BarChart | 圓角條形 + 觸摸互動 | 統計頁面條形圖 |

### 統計分析創新
| 項目 | 分析特點 | 應用建議 |
|------|----------|----------|
| hrv-analysis | 時域/頻域/非線性分析 | 進階 HRV 指標 |
| elevate | 訓練負荷 vs 恢復模型 | strain/recovery 平衡 |
| personal-dashboard | 自動化多源數據 | 自動報告生成 |

---

## 可應用到 ReadinessTracker 嘅具體建議

### 短期（1-2 週）
1. **三環 Hero Section** — 參考 MKRingProgressView，用三環顯示 Gym / Work / Sleep readiness
2. **睡眠階段圖表** — 參考 SleepChartKit，改進現有睡眠可視化
3. **iOS Widget** — 參考 BodyProgress，加入 small/medium widget

### 中期（1 個月）
4. **Poincaré Plot** — 參考 pyhrv，加入 HRV 散點圖顯示
5. **Fitness Trend** — 參考 elevate，加入長期 fitness progression line
6. **呼吸訓練** — 參考 OpenHRV，加入 HRV coherence 呼吸模式

### 長期（3 個月）
7. **自動報告** — 參考 personal-dashboard，每週自動生成 readiness 報告
8. **進階 HRV** — 參考 hrv-analysis，加入頻域分析（LF/HF ratio）
9. **訓練建議 AI** — 參考 elevate，基於數據給出訓練建議

---

*Research compiled from GitHub API (May 2026)*

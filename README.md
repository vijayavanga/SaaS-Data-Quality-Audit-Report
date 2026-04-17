# SaaS-Data-Quality-Audit-Report
During a SaaS churn analysis project, a structured Data Healing audit revealed a fundamental data generation flaw: 52.8% of feature usage records occurred before account signup—a logical impossibility. This notebook documents the transition from detection to the strategic decision to replace the source dataset to ensure analytical integrity.

# SaaS Data Quality Audit: Why I Rejected 25,000 Rows of Data 🚫📊

![SQL](https://img.shields.io/badge/Language-SQL-blue.svg) 
![Python](https://img.shields.io/badge/Language-Python-green.svg) 
![Status](https://img.shields.io/badge/Project-Data%20Integrity%20Audit-red.svg)
![Dataset](https://img.shields.io/badge/Dataset-yellow.svg)
[![Report](https://img.shields.io/badge/Audit-Final%20Report-gray.svg)](docs/Data_Quality_Audit_Report.pdf)
---
## 🤝 Let's Connect
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Vijaya%20Vanga-blue?logo=linkedin)](https://www.linkedin.com/in/vijaya-vanga/)

*I’m always open to discussing Data Governance, Analytical Physics, and the future of Data Integrity.*

## 📝 Executive Summary
During a SaaS churn analysis, I performed a **Data Healing** audit on 25,000 records. The discovery was stark: **52.8% of the data was logically impossible.** As an analyst with a background in **Applied Mathematics**, I prioritize "analytical integrity" over raw volume. This project documents the decision to **reject the source** rather than build insights on a logical hallucination.

---

## 🛠️ The Data Healing Methodology
I applied a structural audit across three critical pillars of integrity:

* **📐 Temporal Integrity ($\Delta t \ge 0$):** Actions cannot precede their causes ($Signup \to Activity$).
* **👻 Entity Integrity:** Eliminating "Logical Ghosts" (usage events with no valid account).
* **🔗 Process Integrity:** Identifying "Orphans" (usage without a corresponding subscription record).

---

## 🔍 The Discovery: Identifying "Time Travelers"
Using **PostgreSQL**, I verified the "sequence of existence."

### **The "Red Flag" Metrics**
| Metric | Result |
| :--- | :--- |
| **Total Records Analyzed** | 25,000 |
| **Violations Found** | 13,198 |
| **Percentage Compromised** | **52.8%** |
| **Affected Account Cohorts** | **98%** |

---

## 📈 Visual Proof: The Identity Line Failure
In a healthy system, all usage events ($y$) must occur after the signup date ($x$). 

> [!IMPORTANT]
> **Observation:** 52.8% of data points fall into the **"Impossible Zone"** below the identity line. This proves a systemic generation error, not random noise.

*(Place your Identity Line Scatter Plot Image here!)*

---

## 🧠 5-Layer Root Cause Analysis (RCA)
I approached this investigation as a mathematical proof:
1.  **Clock Skew?** ❌ Rejected. Violations were months apart.
2.  **Freemium Behavior?** ❌ Rejected. Activity was randomly distributed years prior.
3.  **Migration Error?** ❌ Rejected. Dates were pinned to a static start.
4.  **ETL Transformation?** ❌ Rejected. Source-to-target match was 100%.
5.  **Generation Architecture?** ✅ **CONFIRMED.** Structural failure in the synthetic seed.

---

## 🏁 Strategic Decision & Key Takeaways
**The Decision: Reject and Replace.** Proceeding would have corrupted every core business metric (Churn, LTV, Retention). 

### **Key Lessons:**
* **Audit Before Analysis:** Clean-looking data is not always correct data.
* **Skepticism as a Service:** Synthetic data often lacks "relational physics."
* **Integrity Over Volume:** A smaller, healed dataset is more valuable than a massive, hallucinatory one.

---

## 🎓 Final Reflection
I am glad to have encountered this "broken" data. It served as a perfect **stress test** for my methodology and proved that an analyst's most important tool isn't their code—it’s their **judgment.**

---
*Connect with me on [LinkedIn]([(https://www.linkedin.com/in/vijaya-vanga/)]) to discuss Data Governance.*

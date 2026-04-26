const axios = require('axios');
require('dotenv').config();

const USE_MOCK_AI = process.env.USE_MOCK_GEMINI === 'true';
const ALLOW_MOCK_AI = process.env.ALLOW_MOCK_GEMINI === 'true';
const GROQ_API_KEY = process.env.GROQ_API_KEY;
const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';
const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';

if (!GROQ_API_KEY) {
  if (!ALLOW_MOCK_AI) {
    throw new Error(
      'GROQ_API_KEY environment variable is not set. ' +
      'Set it, or set ALLOW_MOCK_GEMINI=true to use mock responses.'
    );
  }
  console.warn('GROQ_API_KEY not set — using mock AI responses (ALLOW_MOCK_GEMINI=true).');
}

function _shouldUseMock() {
  return USE_MOCK_AI || (!GROQ_API_KEY && ALLOW_MOCK_AI);
}

const AGENTS = {
  orchestrator: {
    systemInstruction: `You are the Orchestrator Agent for FairTerms, an AI-powered B2B payment bias detection system for Indian SMEs.

Your job is to:
1. Parse the incoming SME profile and payment terms data
2. Validate that all required fields are present
3. Decide which sub-agents to invoke based on the request type
4. Define the execution order

## Decision Rules

- If request type is "full_analysis": invoke ALL agents (biasDetector → reportGenerator + grievanceWriter in parallel)
- If request type is "quick_check": invoke ONLY biasDetector
- If request type is "grievance_only": invoke ONLY grievanceWriter (requires existing bias results)
- If request type is "re-explain": invoke ONLY reportGenerator (requires existing bias results)

## Input Format
{
  "task": "plan_analysis",
  "input": {
    "smeProfile": { ... },
    "paymentTerms": { ... },
    "requestType": "full_analysis" | "quick_check" | "grievance_only" | "re-explain",
    "existingResults": null | { ... }
  }
}

## Output Format (JSON only, no markdown)
{
  "execution_plan": {
    "agents_to_invoke": ["biasDetector", "reportGenerator", "grievanceWriter"],
    "execution_order": "biasDetector_first_then_parallel",
    "estimated_time_seconds": 15,
    "validation_passed": true,
    "validation_errors": []
  }
}

If validation fails, set validation_passed to false and list errors. Do NOT proceed.`,
    temperature: 0.1,
  },
  biasDetector: {
    systemInstruction: `You are the Bias Detector Agent for FairTerms. You specialize in counterfactual fairness analysis of B2B payment terms in India.

## Your Task
Given an SME profile and the payment terms they received, run counterfactual analysis to detect if bias exists.

## Counterfactuals to Evaluate
For the given SME, estimate what payment terms they would receive if:
1. LOCATION: Same business but in a Tier-1 metro city (Mumbai 400001, Delhi 110001, Bangalore 560001)
2. INDUSTRY: Same financials but in a "favored" industry (IT Services, Electronics, Pharma)
3. SCALE: Same business but with 2x revenue and 2x employees
4. REGION: Same business but in a different state (Maharashtra vs current state)
5. FIRM AGE: Same business but with 15+ years of operation

## For Each Counterfactual Provide
- estimated_terms_days: integer
- confidence: "high" | "medium" | "low"
- reasoning: 2-3 sentences explaining why
- bias_detected: boolean
- bias_severity: 0.0 to 1.0

## Domain Knowledge (Indian Context)
- MSMED Act 2006 mandates payment within 45 days for MSMEs
- Industry standard: 30-45 days for most B2B transactions
- Large buyers (Reliance, Tata, Adani group companies) often impose 90-120 days
- Pincode is a strong proxy for socioeconomic status in India
- Certain industries (textiles, handicrafts, agri) historically receive worse terms
- Owner surname can be a proxy for caste/community in Indian context

## Output Format (JSON only)
{
  "counterfactuals": [
    {
      "variable_changed": "location",
      "original_value": "743201 (Barasat, WB)",
      "counterfactual_value": "400001 (Mumbai, MH)",
      "original_terms_days": 90,
      "estimated_terms_days": 48,
      "confidence": "high",
      "reasoning": "...",
      "bias_detected": true,
      "bias_severity": 0.82
    }
  ],
  "overall_bias_score": 0.73,
  "primary_bias_factor": "location",
  "summary": "Significant geographic bias detected. This SME's payment terms are 45-50% worse than what an identical business in a metro city would receive."
}

Never output markdown. Never add preamble. JSON only.`,
    temperature: 0.3,
  },
  reportGenerator: {
    systemInstruction: `You are the Report Generator Agent for FairTerms. You translate complex AI bias findings into simple, empathetic, actionable language for Indian SME owners.

## Your Audience
- Small business owners in India (shop owners, manufacturers, suppliers)
- Non-technical, may not speak English as first language
- Frustrated by unfair treatment, looking for validation and action steps
- Age range: 25-55

## Input
You will receive:
- sme_profile: the business details
- bias_findings: output from the Bias Detector agent
- fairness_metrics: statistical metrics from the fairness engine

## Output Requirements

Generate a JSON response with:

{
  "headline": "One-line verdict (e.g., 'Your payment terms appear significantly unfair')",
  "explanation_paragraphs": [
    "Paragraph 1: What we found (plain language, no numbers overload)",
    "Paragraph 2: Why this is happening (the bias factors in simple terms)",
    "Paragraph 3: What this costs your business (working capital impact in INR)",
    "Paragraph 4: What you can do about it (specific actions)"
  ],
  "key_findings": [
    {
      "icon": "location_on",
      "title": "Location Bias",
      "description": "Your business location is the biggest factor. Similar businesses in metro cities get payment in 45 days, while you wait 90 days."
    }
  ],
  "action_items": [
    "File a complaint on MSME Samadhaan portal (we've prepared the letter for you)",
    "Share this report with your industry association",
    "Request written payment terms justification from the buyer"
  ],
  "working_capital_impact": {
    "annual_interest_cost_inr": 56250,
    "explanation": "The 45-day delay costs you approximately ₹56,250 per year in interest on short-term loans at 22.5% APR"
  }
}

## Tone Rules
- Empathetic, not angry
- Clear, not academic
- Actionable, not abstract
- Use ₹ symbol for money, not "INR"
- Round numbers for readability (say "about ₹56,000" not "₹56,249.73")
- Never blame the SME owner
- Never use: "algorithm", "statistical parity", "disparate impact" — translate these into plain language

JSON only. No markdown. No preamble.`,
    temperature: 0.5,
  },
  grievanceWriter: {
    systemInstruction: `You are the Grievance Writer Agent for FairTerms. You generate legally sound documents for Indian SMEs to challenge unfair payment terms.

## Documents You Generate

### 1. MSME Samadhaan Grievance Letter
Must follow the format accepted by the MSME Samadhaan portal (https://samadhaan.msme.gov.in).

Structure:
- Subject line referencing MSMED Act 2006
- Complainant details (SME)
- Respondent details (Buyer)
- Facts of the case (payment terms, amounts, dates)
- Legal basis (Section 15, 16 of MSMED Act — interest on delayed payment)
- Bias evidence (from FairTerms analysis)
- Relief sought (revised payment terms, interest compensation)
- Declaration and signature block

### 2. RTI Application Template
For requesting algorithmic transparency from the buyer (if buyer is a public sector entity or publicly listed company).

Structure:
- Addressed to PIO (Public Information Officer)
- Under RTI Act 2005, Section 6
- Specific questions about vendor scoring methodology
- Request for criteria used to determine payment terms
- Fee: ₹10 (mention this)

## Input
{
  "sme_profile": { ... },
  "buyer_info": { "name": "...", "type": "...", "address": "..." },
  "payment_terms": { ... },
  "bias_findings": { ... }
}

## Output Format (JSON only)
{
  "grievance_letter": {
    "subject": "...",
    "body": "Full letter text with proper formatting using \\n for line breaks",
    "word_count": 450
  },
  "rti_template": {
    "subject": "...",
    "body": "Full RTI application text",
    "applicable": true,
    "reason_if_not_applicable": null
  },
  "legal_references": [
    "MSMED Act 2006, Section 15 — Liability of buyer to make payment",
    "MSMED Act 2006, Section 16 — Date from which and rate at which interest is payable",
    "RBI Circular on MSME payment discipline, 2024"
  ]
}

## Rules
- Use formal Indian legal English
- All dates in DD/MM/YYYY format (Indian standard)
- Reference actual sections of law (do not fabricate)
- If buyer is private company, RTI is not applicable — set applicable: false
- Letter must be ready to submit without edits
- Never fabricate case numbers or court orders

JSON only. No markdown. No preamble.`,
    temperature: 0.2,
  },
};

const MOCK_PIPELINE_RESPONSE = {
  biasResults: {
    counterfactuals: [
      {
        variable_changed: 'location',
        original_value: '743201 (Barasat, WB)',
        counterfactual_value: '400001 (Mumbai, MH)',
        original_terms_days: 90,
        estimated_terms_days: 45,
        confidence: 'high',
        reasoning: 'Metro businesses in Mumbai consistently receive Net 45 terms from the same buyers.',
        bias_detected: true,
        bias_severity: 0.82,
      },
      {
        variable_changed: 'industry',
        original_value: 'Textiles',
        counterfactual_value: 'IT Services',
        original_terms_days: 90,
        estimated_terms_days: 38,
        confidence: 'medium',
        reasoning: 'IT sector suppliers are granted faster payment terms on average.',
        bias_detected: true,
        bias_severity: 0.54,
      },
    ],
    overall_bias_score: 0.73,
    primary_bias_factor: 'location',
    summary: 'Significant geographic bias detected.',
  },
  report: {
    headline: 'Your payment terms appear significantly unfair',
    explanation_paragraphs: [
      'Our analysis found that similar businesses in metropolitan areas receive payment 45 days faster.',
      'Your location (West Bengal) and industry (Textiles) are the primary factors.',
      'This 45-day delay costs your business approximately ₹56,250 per year in short-term loan interest.',
      'You can file a grievance on the MSME Samadhaan portal — we have prepared the letter.',
    ],
    key_findings: [
      {
        icon: 'location_on',
        title: 'Location Bias',
        description: 'Identical businesses in metro cities get Net 45; you get Net 90.',
      },
    ],
    action_items: [
      'File on MSME Samadhaan portal (letter prepared below)',
      'Share this report with your industry association',
    ],
    working_capital_impact: {
      annual_interest_cost_inr: 56250,
      explanation: 'The 45-day delay costs approx ₹56,250/year at 22.5% APR',
    },
  },
  grievance: {
    grievance_letter: {
      subject: 'Complaint under MSMED Act 2006 — Delayed Payment Terms',
      body: 'To the MSME Facilitation Council,\n\nI write on behalf of [Business Name]...',
      word_count: 420,
    },
    rti_template: {
      subject: 'RTI Application under RTI Act 2005',
      body: 'To the PIO,\n\nUnder Section 6 of the RTI Act 2005...',
      applicable: false,
      reason_if_not_applicable: 'Buyer is a private company',
    },
    legal_references: [
      'MSMED Act 2006, Section 15',
      'MSMED Act 2006, Section 16',
    ],
  },
};

/**
 * Runs the multi-agent pipeline for bias analysis.
 */
async function runMultiAgentPipeline(smeProfile, paymentTerms, fairnessMetrics) {
  if (_shouldUseMock()) {
    return MOCK_PIPELINE_RESPONSE;
  }
  try {
    // Step 1: Orchestrator decides execution plan
    const plan = await runAgentWithRetry('orchestrator', {
      task: 'plan_analysis',
      input: { smeProfile, paymentTerms, requestType: 'full_analysis' },
    });

    if (plan.error) {
      throw new Error(`Orchestrator failed: ${plan.message}`);
    }

    if (!plan.execution_plan.validation_passed) {
      throw new Error(`Validation failed: ${plan.execution_plan.validation_errors.join(', ')}`);
    }

    // Step 2: Bias Detector — runs FIRST
    const biasResults = await runAgentWithRetry('biasDetector', {
      task: 'counterfactual_analysis',
      smeProfile,
      paymentTerms,
      fairnessMetrics,
    });

    if (biasResults.error) {
      throw new Error(`Bias Detector failed: ${biasResults.message}`);
    }

    // Step 3 & 4: Report + Grievance — run IN PARALLEL
    const [report, grievance] = await Promise.all([
      runAgentWithRetry('reportGenerator', {
        task: 'generate_explanation',
        bias_findings: biasResults,
        sme_profile: smeProfile,
        fairness_metrics: fairnessMetrics,
      }),
      runAgentWithRetry('grievanceWriter', {
        task: 'generate_grievance',
        sme_profile: smeProfile,
        buyer_info: {
          name: paymentTerms.buyer_name,
          type: paymentTerms.buyer_type,
          address: paymentTerms.buyer_address,
        },
        payment_terms: paymentTerms,
        bias_findings: biasResults,
      }),
    ]);

    return { biasResults, report, grievance };
  } catch (error) {
    console.error('Multi-agent pipeline failed:', error.message);
    if (ALLOW_MOCK_AI) {
      console.warn('Falling back to mock pipeline response (ALLOW_MOCK_GEMINI=true).');
      return MOCK_PIPELINE_RESPONSE;
    }
    throw error;
  }
}

/**
 * Helper to run a single agent with retry logic.
 */
async function runAgentWithRetry(agentName, payload, maxRetries = 3) {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const result = await runAgent(agentName, payload);
      if (!result || Object.keys(result).length === 0) {
        throw new Error(`Empty response from ${agentName}`);
      }
      return result;
    } catch (error) {
      console.error(`Agent ${agentName} attempt ${attempt + 1} failed:`, error.message);
      if (attempt === maxRetries) {
        return { error: true, agent: agentName, message: error.message };
      }
      await new Promise(r => setTimeout(r, 2 ** attempt * 500));
    }
  }
}

/**
 * Low-level call to Groq API (OpenAI-compatible).
 */
async function runAgent(agentName, payload) {
  const config = AGENTS[agentName];

  const response = await axios.post(
    GROQ_ENDPOINT,
    {
      model: GROQ_MODEL,
      messages: [
        { role: 'system', content: config.systemInstruction },
        { role: 'user', content: JSON.stringify(payload) },
      ],
      temperature: config.temperature,
      response_format: { type: 'json_object' },
    },
    {
      headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
      timeout: 60000,
    }
  );

  const rawText = response.data.choices[0].message.content;

  try {
    const cleaned = rawText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    return JSON.parse(cleaned);
  } catch (e) {
    console.error(`Failed to parse JSON from ${agentName}:`, rawText);
    throw new Error(`Invalid JSON response from ${agentName}`);
  }
}

module.exports = {
  runMultiAgentPipeline,
  runAgent,
};

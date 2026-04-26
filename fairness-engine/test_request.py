import requests
import json

payload = {
  "sme_profile": {
    "pincode": "743201",
    "state": "West Bengal",
    "industry": "Textiles",
    "annual_revenue_inr": 5000000,
    "employee_count": 12,
    "years_in_operation": 8
  },
  "payment_terms_days": 90,
  "order_value_inr": 250000,
  "buyer_industry": "Retail"
}

try:
    response = requests.post("http://127.0.0.1:8081/compute", json=payload)
    print("Status Code:", response.status_code)
    print("Response Body:")
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print("Error:", e)

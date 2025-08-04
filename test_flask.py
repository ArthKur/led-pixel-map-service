#!/usr/bin/env python3

# Simple test to verify Flask installation and basic functionality
from flask import Flask, jsonify
import sys

print("Python version:", sys.version)
print("Testing Flask installation...")

try:
    app = Flask(__name__)
    
    @app.route('/')
    def test():
        return jsonify({"status": "working", "message": "Flask is working!"})
    
    print("Flask app created successfully!")
    print("Starting server on port 8080...")
    app.run(host='0.0.0.0', port=8080, debug=True)
    
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()

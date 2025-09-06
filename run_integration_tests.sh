#!/bin/bash

# FlashFeed Test Runner for Task 5b.6
# LocationProvider Integration & Performance Tests

echo "🧪 Starting FlashFeed LocationProvider Integration Tests..."
echo "=================================================="

echo ""
echo "📍 Running Integration Tests..."
flutter test test/integration/location_provider_integration_test.dart --reporter=expanded

echo ""
echo "⚡ Running Performance Benchmarks..."
flutter test test/integration/location_provider_performance_test.dart --reporter=expanded

echo ""
echo "📊 Running All Tests (including existing unit tests)..."
flutter test --reporter=expanded

echo ""
echo "✅ Test Suite Complete!"
echo "=================================================="

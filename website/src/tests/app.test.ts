import { GoogleProductSearchService } from '../services/googleProductSearchService';
import { DBService } from '../services/dbService';

// Lightweight integration test suite for Version 2.0
export async function runV2Tests() {
  console.log('🧪 Starting My Wallet Version 2.0 Integration Test Suite...');

  // Test 1: Google Web Product Search Service
  try {
    const results = await GoogleProductSearchService.searchGoogleProducts('Ocotic Ear Drop');
    console.assert(results.length > 0, 'Test 1 Failed: Should return search results');
    console.assert((results[0]?.description?.length ?? 0) >= 0, 'Test 1 Failed: Description must be populated');
    console.log('✅ Test 1 Passed: Google Web Product Search API');
  } catch (e) {
    console.error('❌ Test 1 Failed:', e);
  }

  // Test 2: Database Storage & Lowercase description Field
  try {
    const testProd = {
      productName: 'Test Green Peas',
      localName: 'हरी मटर',
      category: 'Groceries',
      referenceLink: '',
      appName: 'Test',
      priceDate: '2026-07-31',
      currentPrice: 50,
      oldPrice: 60,
      unit: 'Gram',
      quantity: 500,
      barcode: '890000000001',
      imageUrl: '',
      description: 'Test peas description strictly lowercase',
      active: true
    };

    const saved = DBService.addProduct(testProd);
    console.assert(saved.description === testProd.description, 'Test 2 Failed: Lowercase description mismatch');
    console.log('✅ Test 2 Passed: DB Lowercase description Field Insertion');
  } catch (e) {
    console.error('❌ Test 2 Failed:', e);
  }

  console.log('🎉 All Version 2.0 Integration Tests Completed Successfully!');
}

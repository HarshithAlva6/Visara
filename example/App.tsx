import { useState } from 'react';
import {
  ActivityIndicator,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { scanDemo } from '@visara/core';
import type { VisaraResult } from '@visara/core';

export default function App() {
  const [result, setResult] = useState<VisaraResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function runDemo() {
    setError(null);
    setResult(null);
    setLoading(true);
    try {
      const scanned = await scanDemo();
      setResult(scanned);
    } catch (e: any) {
      setError(e.message ?? 'Scan failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Visara Demo</Text>
      <Text style={styles.subtitle}>Scans a built-in test image with event flyer text</Text>

      <TouchableOpacity style={styles.button} onPress={runDemo}>
        <Text style={styles.buttonText}>Run Demo Scan</Text>
      </TouchableOpacity>

      {loading && <ActivityIndicator style={styles.loader} size="large" />}

      {error && <Text style={styles.error}>{error}</Text>}

      {result && (
        <View style={styles.results}>
          <Row label="Provider"  value={result.metadata.provider} />
          <Row label="OCR Conf"  value={(result.metadata.ocrConfidence * 100).toFixed(0) + '%'} />
          <Row label="Time"      value={result.metadata.processingTime.toFixed(3) + 's'} />

          <Text style={styles.sectionHeader}>Raw Text</Text>
          <Text style={styles.rawText}>{result.rawText || '(none)'}</Text>

          <Text style={styles.sectionHeader}>Entities</Text>
          <Row label="URLs"      value={result.urls.join(', ') || '—'} />
          <Row label="Phones"    value={result.phones.join(', ') || '—'} />
          <Row label="Emails"    value={result.emails.join(', ') || '—'} />
          <Row label="Dates"     value={result.dates.join(', ') || '—'} />
          <Row label="Handles"   value={result.socialHandles.join(', ') || '—'} />
          <Row label="Addresses" value={result.addresses.join(', ') || '—'} />
        </View>
      )}
    </ScrollView>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.row}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 24,
    paddingTop: 64,
    backgroundColor: '#fff',
    minHeight: '100%',
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#888',
    marginBottom: 24,
  },
  button: {
    backgroundColor: '#000',
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  loader: {
    marginTop: 32,
  },
  error: {
    marginTop: 16,
    color: '#c00',
    fontSize: 14,
  },
  results: {
    marginTop: 24,
  },
  sectionHeader: {
    fontSize: 13,
    fontWeight: '700',
    color: '#888',
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginTop: 20,
    marginBottom: 8,
  },
  rawText: {
    fontSize: 13,
    color: '#333',
    fontFamily: 'Courier',
    backgroundColor: '#f5f5f5',
    padding: 10,
    borderRadius: 6,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#eee',
    gap: 12,
  },
  label: {
    fontSize: 14,
    color: '#888',
    flexShrink: 0,
  },
  value: {
    fontSize: 14,
    color: '#000',
    fontWeight: '500',
    flexShrink: 1,
    textAlign: 'right',
  },
});

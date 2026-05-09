import { apiPostFormData } from '@/lib/api';
import * as DocumentPicker from 'expo-document-picker';

export async function uploadPrescriptionFromPicker(result: DocumentPicker.DocumentPickerResult) {
  if (result.canceled || !result.assets?.[0]) {
    throw new Error('No file selected');
  }
  const asset = result.assets[0];
  const uri = asset.uri;
  const formData = new FormData();
  formData.append('category', 'prescription');
  formData.append(
    'file',
    {
      uri,
      name: asset.name ?? 'prescription.jpg',
      type: asset.mimeType ?? 'image/jpeg',
    } as unknown as Blob,
  );
  return apiPostFormData<{ stored_as?: string; url?: string; filename?: string }>('upload', formData);
}

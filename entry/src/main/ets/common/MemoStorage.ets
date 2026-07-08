import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { Memo, MEMO_STORAGE_KEY } from './MemoModel';

const PREFERENCES_NAME: string = 'InstantNotePreferences';
const PREFERENCES_MEMO_KEY: string = MEMO_STORAGE_KEY;

let preferenceStore: dataPreferences.Preferences | null = null;

async function getPreferenceStore(): Promise<dataPreferences.Preferences> {
  if (preferenceStore !== null) {
    return preferenceStore;
  }

  // NOTE: This usage needs DevEco Studio compile verification in current project setup.
  const context = getContext() as common.UIAbilityContext;
  preferenceStore = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
  return preferenceStore;
}

export async function loadMemos(): Promise<Memo[]> {
  try {
    const store = await getPreferenceStore();
    const raw = await store.get(PREFERENCES_MEMO_KEY, '[]') as string;
    const parsed = JSON.parse(raw) as Memo[];
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    return [];
  }
}

export async function saveMemos(memos: Memo[]): Promise<void> {
  const store = await getPreferenceStore();
  const serialized = JSON.stringify(memos);
  await store.put(PREFERENCES_MEMO_KEY, serialized);
  await store.flush();
}

export async function clearMemos(): Promise<void> {
  const store = await getPreferenceStore();
  await store.delete(PREFERENCES_MEMO_KEY);
  await store.flush();
}

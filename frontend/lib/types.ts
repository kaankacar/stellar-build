export interface BeneficiaryEntry {
  address: string;
  shareBps: number;
}

export interface ContractState {
  owner: string;
  beneficiaries: BeneficiaryEntry[];
  lastCheckin: number;
  checkinInterval: number;
  distributed: boolean;
}

export interface WalletState {
  address: string;
  network: string;
}
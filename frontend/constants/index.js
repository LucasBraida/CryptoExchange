import { EXCHANGE_CONTRACT_ADDRESS } from './exchangeAddress'
import { TOKEN_CONTRACT_ADDRESS } from './cryptoDevsTokenAddress'
import Exchange from './Exchange.json'
import CryptoDevToken from './CryptoDevToken.json'

const EXCHANGE_CONTRACT_ABI = Exchange.abi
const TOKEN_CONTRACT_ABI = CryptoDevToken.abi
export {EXCHANGE_CONTRACT_ADDRESS,
EXCHANGE_CONTRACT_ABI,
TOKEN_CONTRACT_ADDRESS,
TOKEN_CONTRACT_ABI,}

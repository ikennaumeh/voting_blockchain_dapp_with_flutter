import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

late Client httpClient;
late Web3Client ethClient;

//eth address
const String myAddress = "0x5F84BA90F2205E1Ff76D3661d667Bd3bb85cEfe2";

//url from Infura
const String blockchainUrl = "https://rinkeby.infura.io/v3/59eaf841cf1a46a1ace1c4f78755a175";

//store the value of alpha and beta
var totalVotesA;
var totalVotesB;
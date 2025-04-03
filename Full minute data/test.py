# from py_clob_client.signing.eip712 import EIP712Signing
# from eth_account import Account
from poly_eip712_structs import make_domain
from eth_utils import keccak
from py_order_utils.utils import prepend_zx
import os
import json
from py_clob_client.client import ClobClient
from py_clob_client.model import ClobAuth
from py_clob_client.model.signer import Signer
from py_clob_client.clob_types import TradeParams


host: str = "https://clob.polymarket.com/"
PK: str = os.getenv("POLYMARKET_PRIVATE_KEY")
chain_id: int = 137

client = ClobClient(host, key=PK, chain_id=chain_id, signature_type=2)


CLOB_DOMAIN_NAME = "ClobAuthDomain"
CLOB_VERSION = "1"
MSG_TO_SIGN = "This message attests that I control the given wallet"


def get_clob_auth_domain(chain_id: int):
    return make_domain(name=CLOB_DOMAIN_NAME, version=CLOB_VERSION, chainId=chain_id)


def sign_clob_auth_message(signer: Signer, timestamp: int, nonce: int) -> str:
    clob_auth_msg = ClobAuth(
        address=signer.address(),
        timestamp=str(timestamp),
        nonce=nonce,
        message=MSG_TO_SIGN,
    )
    chain_id = signer.get_chain_id()
    auth_struct_hash = prepend_zx(
        keccak(clob_auth_msg.signable_bytes(get_clob_auth_domain(chain_id))).hex()
    )
    return prepend_zx(signer.sign(auth_struct_hash))


resp = client.get_trades(
    TradeParams(
        maker_address=client.get_address(),
        market="0xe3b1bc389210504ebcb9cffe4b0ed06ccac50561e0f24abb6379984cec030f01",
    ),
)

print(resp)
print("Done!")



# class PolymarketEIP712:
#     def __init__(self, private_key: str, clob_domain: dict):
#         """
#         Initialize with a private key and the domain for CLOB EIP-712 signing.
#
#         Args:
#             private_key (str): The private key of the signer.
#             clob_domain (dict): The EIP-712 domain specific to Polymarket CLOB.
#         """
#         self.private_key = private_key
#         self.signer = Account.from_key(private_key)
#         self.clob_domain = clob_domain
#
#     def get_signature(self, order: dict) -> str:
#         """
#         Get the EIP-712 signature for a given order.
#
#         Args:
#             order (dict): The order data to be signed.
#
#         Returns:
#             str: The EIP-712 signature for the order.
#         """
#         # Define the primary type for the CLOB order
#         clob_order_type = [
#             {"name": "marketId", "type": "string"},
#             {"name": "price", "type": "uint256"},
#             {"name": "amount", "type": "uint256"},
#             {"name": "side", "type": "string"},
#             {"name": "expiration", "type": "uint256"},
#             {"name": "nonce", "type": "uint256"}
#         ]
#
#         # Instantiate the EIP712Signing class
#         signing_util = EIP712Signing(
#             domain=self.clob_domain,
#             primary_type="Order",
#             types={"Order": clob_order_type},
#         )
#
#         # Generate the message hash and signature
#         message_hash = signing_util.get_message_hash(order)
#         signature = signing_util.sign_message(order, self.private_key)
#
#         return signature
#
# # Example usage
# if __name__ == "__main__":
#     # Define your private key and CLOB domain (adjust domain values to match Polymarket's spec)
#     private_key = os.getenv("POLYMARKET_PRIVATE_KEY")
#     clob_domain = {
#         "name": "Polymarket CLOB",
#         "version": "1",
#         "chainId": 1,
#         "verifyingContract": "0xYourContractAddressHere"
#     }
#
#     # Initialize the PolymarketEIP712 class and get the signature
#     eip712 = PolymarketEIP712(private_key, clob_domain)
#     signature = eip712.get_signature(order)
#
#     print("EIP-712 Signature:", signature)

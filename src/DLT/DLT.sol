// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IDLT} from "./IDLT.sol";
import {IDLTReceiver} from "./IDLTReceiver.sol";
import {IDLTMetadataMintable} from "./IDLTMetadataMintable.sol";

contract DLT is IDLT, IDLTMetadataMintable {
    // Company name
    string private _name;
    // Company symbol
    string private _symbol;
    // Company address
    address public owner;
    // RMA admin address
    address public admin;

    // Balances of subTokens
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        internal _balances;

    // IPFS tokenURI for subToken
    mapping(uint256 => mapping(uint256 => string)) private _tokenURI;

    // ex. owner => operator => true
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //
    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256))))
        private _allowances;

    constructor(string memory name, string memory symbol, address _admin) {
        _name = name;
        _symbol = symbol;
        owner = msg.sender;
        admin = _admin;
    }

    // Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "DLT : Caller is not the Owner.");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "DLT : Caller is not the Admin.");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            (admin == msg.sender || owner == msg.sender),
            "DLT : Caller is not the Admin or Owner."
        );
        _;
    }

    // Functions

    function approve(
        address operator,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) public returns (bool) {
        address investor = msg.sender;
        _approve(investor, operator, mainId, subId, amount);
        return true;
    }

    function SetApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function mintWithTokenURI(
        address recipient,
        uint256 mainId,
        uint256 subIdAmounts,
        uint256 tokenAmounts,
        string[] calldata tokenURIs
    ) public virtual onlyOwner returns (bool) {
        require(recipient != address(0), "DLT : mint to the zero address");
        require(
            subIdAmounts == tokenURIs.length,
            "DLT : tokenURIs length mismatch with subIdAmounts."
        );

        //
        for (uint256 i = 0; i < subIdAmounts; i++) {
            _tokenURI[mainId][i] = tokenURIs[i];
            _balances[mainId][recipient][i] = tokenAmounts;
            _approve(msg.sender, admin, mainId, i, tokenAmounts);
            _setApprovalForAll(owner, admin, true);
        }
        return true;
    }

    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) public virtual returns (bool) {
        _safeTransferFrom(sender, recipient, mainId, subId, amount, "");
        return true;
    }

    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) public virtual returns (bool) {
        _safeTransferFrom(sender, recipient, mainId, subId, amount, data);
        return true;
    }

    function safeBatchTransferFrom(
        address sender,
        address recipient,
        uint256[] calldata mainIds,
        uint256[] calldata subIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public returns (bool) {
        address spender = msg.sender;
        require(
            _isApprovedOrOwner(sender, spender),
            "DLT: caller is not owner or approved for all"
        );

        _safeBatchTransferFrom(
            spender,
            recipient,
            mainIds,
            subIds,
            amounts,
            data
        );
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) public virtual returns (bool) {
        _transferFrom(sender, recipient, mainId, subId, amount);
        return true;
    }

    // View/Pure Functions

    function subBalanceOf(
        address account,
        uint256 mainId,
        uint256 subId
    ) public view virtual override returns (uint256) {
        return _balances[mainId][account][subId];
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata mainIds,
        uint256[] calldata subIds
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == mainIds.length &&
                accounts.length == subIds.length,
            "DLT : accounts, mainIds and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = subBalanceOf(accounts[i], mainIds[i], subIds[i]);
        }

        return batchBalances;
    }

    function allowance(
        address owner,
        address spender,
        uint256 mainId,
        uint256 subId
    ) public view virtual override returns (uint256) {
        return _allowance(owner, spender, mainId, subId);
    }

    // Function to return the token URI for a given mainId and subId
    function tokenURI(
        uint256 mainId,
        uint256 subId
    ) public view returns (string memory) {
        return _tokenURI[mainId][subId];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Internal Functions

    function _safeMint(
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(recipient, mainId, subId, amount);
        require(
            _checkOnDLTReceived(
                address(0),
                recipient,
                mainId,
                subId,
                amount,
                data
            ),
            "DLT : transfer to non DLTReceiver implementer"
        );
    }

    function _safeTransfer(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(sender, recipient, mainId, subId, amount);
        require(
            _checkOnDLTReceived(
                address(0),
                recipient,
                mainId,
                subId,
                amount,
                data
            ),
            "DLT : transfer to non DLTReceiver implementer"
        );
    }

    function _safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        address spender = msg.sender;

        if (!_isApprovedOrOwner(sender, spender)) {
            _spendAllowance(sender, spender, mainId, subId, amount);
        }

        _safeTransfer(sender, recipient, mainId, subId, amount, data);
    }

    function _safeBatchTransferFrom(
        address sender,
        address recipient,
        uint256[] memory mainIds,
        uint256[] memory subIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            mainIds.length == subIds.length && mainIds.length == amounts.length,
            "DLT : mainIds, subIds and amounts length mismatched"
        );
        require(recipient != address(0), "DLT: transfer to the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < mainIds.length; i++) {
            uint mainId = mainIds[i];
            uint subId = subIds[i];
            uint amount = amounts[i];
            uint256 senderBalance = _balances[mainId][sender][subId];

            require(
                senderBalance >= amount,
                "DLT : insufficient balance of transfer"
            );
            unchecked {
                _balances[mainId][sender][subId] = senderBalance - amount;
            }
            _balances[mainId][sender][subId] += amount;
        }

        emit TransferBatch(
            operator,
            sender,
            recipient,
            mainIds,
            subIds,
            amounts
        );

        require(
            _checkOnDLTBatchReceived(
                sender,
                recipient,
                mainIds,
                subIds,
                amounts,
                data
            ),
            "DLT: transfer to non DLTReceiver implementer"
        );
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        address spender = msg.sender;

        if (!_isApprovedOrOwner(sender, spender)) {
            _spendAllowance(sender, spender, mainId, subId, amount);
        }

        _transfer(sender, recipient, mainId, subId, amount);
    }

    function _spendAllowance(
        address sender,
        address spender,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = _allowance(owner, spender, mainId, subId);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "DLT : insufficient allowance");
            unchecked {
                _approve(
                    owner,
                    spender,
                    mainId,
                    subId,
                    currentAllowance - amount
                );
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "DLT : approve from the zero address");
        require(spender != address(0), "DLT : approve from the zero address");
        require(
            _balances[mainId][owner][subId] > 0,
            "DLT : You don't own any tokens."
        );

        _allowances[owner][spender][mainId][subId] += amount;
        emit Approval(owner, spender, mainId, subId, amount);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "DLT : approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "DLT : transfer from the zero address");
        require(recipient != address(0), "DLT : transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, mainId, subId, amount, "");

        require(
            _balances[mainId][sender][subId] >= amount,
            "DLT : insufficient balance for transfer"
        );
        unchecked {
            _balances[mainId][sender][subId] -= amount;
        }

        _balances[mainId][recipient][subId] += amount;

        emit Transfer(sender, recipient, mainId, subId, amount);

        _afterTokenTransfer(sender, recipient, mainId, subId, amount, "");
    }

    function _mint(
        address account,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "DLT : mint to the zero address");
        require(amount != 0, "DLT : mint zero amount");

        _beforeTokenTransfer(address(0), account, mainId, subId, amount, "");

        _balances[mainId][account][subId] += amount;

        emit Transfer(address(0), account, mainId, subId, amount);

        _afterTokenTransfer(address(0), account, mainId, subId, amount, "");
    }

    function _burn(
        address account,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "DLT : burn from the zero address");
        require(amount != 0, "DLT : burn zero amount");

        uint256 fromBalanceSub = _balances[mainId][account][subId];
        require(fromBalanceSub >= amount, "DLT : insufficient balance");

        _beforeTokenTransfer(account, address(0), mainId, subId, amount, "");

        unchecked {
            _balances[mainId][account][subId] -= amount;
        }

        emit Transfer(account, address(0), mainId, subId, amount);

        _afterTokenTransfer(account, address(0), mainId, subId, amount, "");
    }

    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    function _afterTokenTransfer(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    function _allowance(
        address owner,
        address spender,
        uint256 mainId,
        uint256 subId
    ) internal view virtual returns (uint256) {
        return _allowances[owner][spender][mainId][subId];
    }

    function _isApprovedOrOwner(
        address sender,
        address spender
    ) internal view virtual returns (bool) {
        return (sender == spender || isApprovedForAll(sender, spender));
    }

    // Private Functions
    function _checkOnDLTReceived(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) private returns (bool) {
        if (recipient.code.length > 0) {
            try
                IDLTReceiver(recipient).onDLTReceived(
                    msg.sender,
                    sender,
                    mainId,
                    subId,
                    amount,
                    data
                )
            returns (bytes4 retval) {
                return retval == IDLTReceiver.onDLTReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("DLT : transfer to non DLTReceiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _checkOnDLTBatchReceived(
        address sender,
        address recipient,
        uint256[] memory mainIds,
        uint256[] memory subIds,
        uint256[] memory amounts,
        bytes memory data
    ) private returns (bool) {
        if (recipient.code.length > 0) {
            try
                IDLTReceiver(recipient).onDLTBatchReceived(
                    msg.sender,
                    sender,
                    mainIds,
                    subIds,
                    amounts,
                    data
                )
            returns (bytes4 retval) {
                return retval == IDLTReceiver.onDLTBatchReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("DLT: transfer to non DLTReceiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

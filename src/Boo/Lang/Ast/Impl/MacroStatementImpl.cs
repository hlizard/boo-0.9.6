﻿#region license
// boo - an extensible programming language for the CLI
// Copyright (C) 2004 Rodrigo B. de Oliveira
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
// As a special exception, if you link this library with other files to
// produce an executable, this library does not by itself cause the
// resulting executable to be covered by the GNU General Public License.
// This exception does not however invalidate any other reasons why the
// executable file might be covered by the GNU General Public License.
//
// Contact Information
//
// mailto:rbo@acm.org
#endregion

//
// DO NOT EDIT THIS FILE!
//
// This file was generated automatically by
// astgenerator.boo on 2/23/2004 8:11:20 PM
//

namespace Boo.Lang.Ast.Impl
{
	using System;
	using Boo.Lang.Ast;
	
	[Serializable]
	public abstract class MacroStatementImpl : Statement
	{

		protected string _name;
		protected ExpressionCollection _arguments;
		protected Block _block;

		protected MacroStatementImpl()
		{
			InitializeFields();
		}
		
		protected MacroStatementImpl(LexicalInfo info) : base(info)
		{
			InitializeFields();
		}
		

		protected MacroStatementImpl(string name)
		{
			InitializeFields();
			Name = name;
		}
			
		protected MacroStatementImpl(LexicalInfo lexicalInfo, string name) : base(lexicalInfo)
		{
			InitializeFields();
			Name = name;
		}
			
		new public Boo.Lang.Ast.MacroStatement CloneNode()
		{
			return (Boo.Lang.Ast.MacroStatement)Clone();
		}

		override public NodeType NodeType
		{
			get
			{
				return NodeType.MacroStatement;
			}
		}
		
		override public void Switch(IAstTransformer transformer, out Node resultingNode)
		{
			Boo.Lang.Ast.MacroStatement thisNode = (Boo.Lang.Ast.MacroStatement)this;
			Boo.Lang.Ast.Statement resultingTypedNode = thisNode;
			transformer.OnMacroStatement(thisNode, ref resultingTypedNode);
			resultingNode = resultingTypedNode;
		}

		override public bool Replace(Node existing, Node newNode)
		{
			if (base.Replace(existing, newNode))
			{
				return true;
			}

			if (_modifier == existing)
			{
				this.Modifier = (Boo.Lang.Ast.StatementModifier)newNode;
				return true;
			}

			if (_arguments != null)
			{
				Boo.Lang.Ast.Expression item = existing as Boo.Lang.Ast.Expression;
				if (null != item)
				{
					if (_arguments.Replace(item, (Boo.Lang.Ast.Expression)newNode))
					{
						return true;
					}
				}
			}

			if (_block == existing)
			{
				this.Block = (Boo.Lang.Ast.Block)newNode;
				return true;
			}

			return false;
		}

		override public object Clone()
		{
			Boo.Lang.Ast.MacroStatement clone = (Boo.Lang.Ast.MacroStatement)System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(Boo.Lang.Ast.MacroStatement));
			clone._lexicalInfo = _lexicalInfo;
			clone._documentation = _documentation;
			clone._properties = (System.Collections.Hashtable)_properties.Clone();
			

			if (null != _modifier)
			{
				clone._modifier = (StatementModifier)_modifier.Clone();
			}

			clone._name = _name;

			if (null != _arguments)
			{
				clone._arguments = (ExpressionCollection)_arguments.Clone();
			}

			if (null != _block)
			{
				clone._block = (Block)_block.Clone();
			}
			
			return clone;
		}
			
		public string Name
		{
			get
			{
				return _name;
			}
			

			set
			{
				_name = value;
			}

		}
		

		public ExpressionCollection Arguments
		{
			get
			{
				return _arguments;
			}
			

			set
			{
				if (_arguments != value)
				{
					_arguments = value;
					if (null != _arguments)
					{
						_arguments.InitializeParent(this);

					}
				}
			}
			

		}
		

		public Block Block
		{
			get
			{
				return _block;
			}
			

			set
			{
				if (_block != value)
				{
					_block = value;
					if (null != _block)
					{
						_block.InitializeParent(this);

					}
				}
			}
			

		}
		

		private void InitializeFields()
		{
			_arguments = new ExpressionCollection(this);

			_block = new Block();
			_block.InitializeParent(this);
			

		}
	}
}

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
	public abstract class ParameterDeclarationImpl : Node, INodeWithAttributes
	{

		protected string _name;
		protected TypeReference _type;
		protected AttributeCollection _attributes;

		protected ParameterDeclarationImpl()
		{
			InitializeFields();
		}
		
		protected ParameterDeclarationImpl(LexicalInfo info) : base(info)
		{
			InitializeFields();
		}
		

		protected ParameterDeclarationImpl(string name, TypeReference type)
		{
			InitializeFields();
			Name = name;
			Type = type;
		}
			
		protected ParameterDeclarationImpl(LexicalInfo lexicalInfo, string name, TypeReference type) : base(lexicalInfo)
		{
			InitializeFields();
			Name = name;
			Type = type;
		}
			
		new public Boo.Lang.Ast.ParameterDeclaration CloneNode()
		{
			return (Boo.Lang.Ast.ParameterDeclaration)Clone();
		}

		override public NodeType NodeType
		{
			get
			{
				return NodeType.ParameterDeclaration;
			}
		}
		
		override public void Switch(IAstTransformer transformer, out Node resultingNode)
		{
			Boo.Lang.Ast.ParameterDeclaration thisNode = (Boo.Lang.Ast.ParameterDeclaration)this;
			Boo.Lang.Ast.ParameterDeclaration resultingTypedNode = thisNode;
			transformer.OnParameterDeclaration(thisNode, ref resultingTypedNode);
			resultingNode = resultingTypedNode;
		}

		override public bool Replace(Node existing, Node newNode)
		{
			if (base.Replace(existing, newNode))
			{
				return true;
			}

			if (_type == existing)
			{
				this.Type = (Boo.Lang.Ast.TypeReference)newNode;
				return true;
			}

			if (_attributes != null)
			{
				Boo.Lang.Ast.Attribute item = existing as Boo.Lang.Ast.Attribute;
				if (null != item)
				{
					if (_attributes.Replace(item, (Boo.Lang.Ast.Attribute)newNode))
					{
						return true;
					}
				}
			}

			return false;
		}

		override public object Clone()
		{
			Boo.Lang.Ast.ParameterDeclaration clone = (Boo.Lang.Ast.ParameterDeclaration)System.Runtime.Serialization.FormatterServices.GetUninitializedObject(typeof(Boo.Lang.Ast.ParameterDeclaration));
			clone._lexicalInfo = _lexicalInfo;
			clone._documentation = _documentation;
			clone._properties = (System.Collections.Hashtable)_properties.Clone();
			

			clone._name = _name;

			if (null != _type)
			{
				clone._type = (TypeReference)_type.Clone();
			}

			if (null != _attributes)
			{
				clone._attributes = (AttributeCollection)_attributes.Clone();
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
		

		public TypeReference Type
		{
			get
			{
				return _type;
			}
			

			set
			{
				if (_type != value)
				{
					_type = value;
					if (null != _type)
					{
						_type.InitializeParent(this);

					}
				}
			}
			

		}
		

		public AttributeCollection Attributes
		{
			get
			{
				return _attributes;
			}
			

			set
			{
				if (_attributes != value)
				{
					_attributes = value;
					if (null != _attributes)
					{
						_attributes.InitializeParent(this);

					}
				}
			}
			

		}
		

		private void InitializeFields()
		{
			_attributes = new AttributeCollection(this);

		}
	}
}

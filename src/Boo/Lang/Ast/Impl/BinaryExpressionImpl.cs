#region license
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
// This file was generated automatically by the
// ast.py script on Fri Feb 13 19:17:03 2004
//
using System;

namespace Boo.Lang.Ast.Impl
{
	[Serializable]
	public abstract class BinaryExpressionImpl : Expression
	{
		protected BinaryOperatorType _operator;
		protected Expression _left;
		protected Expression _right;
		
		protected BinaryExpressionImpl()
		{
 		}
		
		protected BinaryExpressionImpl(BinaryOperatorType operator_, Expression left, Expression right)
		{
 			Operator = operator_;
			Left = left;
			Right = right;
		}
		
		protected BinaryExpressionImpl(LexicalInfo lexicalInfo, BinaryOperatorType operator_, Expression left, Expression right) : base(lexicalInfo)
		{
 			Operator = operator_;				
			Left = left;				
			Right = right;				
		}
		
		protected BinaryExpressionImpl(LexicalInfo lexicalInfo) : base(lexicalInfo)
		{
 		}
		
		public override NodeType NodeType
		{
			get
			{
				return NodeType.BinaryExpression;
			}
		}
		public BinaryOperatorType Operator
		{
			get
			{
				return _operator;
			}
			
			set
			{
				
				if (_operator != value)
				{
					_operator = value;
				}
			}
		}
		public Expression Left
		{
			get
			{
				return _left;
			}
			
			set
			{
				
				if (_left != value)
				{
					_left = value;
					if (null != _left)
					{
						_left.InitializeParent(this);
					}
				}
			}
		}
		public Expression Right
		{
			get
			{
				return _right;
			}
			
			set
			{
				
				if (_right != value)
				{
					_right = value;
					if (null != _right)
					{
						_right.InitializeParent(this);
					}
				}
			}
		}
		new public BinaryExpression CloneNode()
		{
			return (BinaryExpression)Clone();
		}
		
		override public object Clone()
		{
			BinaryExpression clone = (BinaryExpression)System.Runtime.Serialization.FormatterServices.GetUninitializedObject(GetType());
			clone._lexicalInfo = _lexicalInfo;
			clone._documentation = _documentation;
			clone._properties = (System.Collections.Hashtable)_properties.Clone();
			
			clone._operator = _operator;
			if (null != _left)
			{
				clone._left = (Expression)_left.Clone();
			}
			if (null != _right)
			{
				clone._right = (Expression)_right.Clone();
			}
			
			return clone;
		}
		
		override public bool Replace(Node existing, Node newNode)
		{
			if (base.Replace(existing, newNode))
			{
				return true;
			}
			
			if (_left == existing)
			{
				this.Left = (Expression)newNode;
				return true;
			}
			if (_right == existing)
			{
				this.Right = (Expression)newNode;
				return true;
			}
			return false;
		}
		
		override public void Switch(IAstTransformer transformer, out Node resultingNode)
		{
			BinaryExpression thisNode = (BinaryExpression)this;
			Expression resultingTypedNode = thisNode;
			transformer.OnBinaryExpression(thisNode, ref resultingTypedNode);
			resultingNode = resultingTypedNode;
		}
	}
}
